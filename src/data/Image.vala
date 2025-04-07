public class Image : Object, Undoable, Updatable, Transformed, Container {
    private File _file;
    private CommandStack stack;
    private Gee.Queue<Error> errors;

    private int _width;
    public int width { get { return _width; } }
    private int _height;
    public int height { get { return _height; } }

    private string? _name;
    public string name {
        get {
            return _name ?? "Untitled";
        }
    }

    public override Gtk.TreeListModel tree { get; set; }
    public override Element? selected_child { get; set; }
    public Transform transform { get; set; }
    private Transform applied_transform;
    private Element? applied_element;

    public Error? error {
        owned get {
            return errors.peek ();
        }
    }

    public signal void error_available ();

    public void resolve_error () {
        // All errors are designed to be handled when detected; this approves the handling that
        // was already done.
        errors.poll ();
    }

    protected Gee.Map<Element, Container.ElementSignalManager> signal_managers { get; set; }

    private uint save_id;

    public ModelUpdate updator {
        set {
            do_update (value);
        }
    }

    private void setup_signals () {
        update.connect (() => {
            if (save_id != 0) {
                Source.remove (save_id);
            }

            save_id = Timeout.add (100, () => {
                save_id = 0;
                if (errors.size == 0) {
                    save_xml ();
                }
                return false;
            });
        });
        apply_transform.connect ((atransform, element) => {
            if (applied_element != null) {
                applied_element.transform_applied = false;
            }

            applied_transform = atransform;
            applied_element = element;
        });
    }

    construct {
        transform = new Transform.identity ();
        applied_transform = new Transform.identity ();
        stack = new CommandStack ();
        var model = new ListStore (typeof (Element));
        this.tree = new Gtk.TreeListModel (model, false, false, get_children);
        signal_managers = new Gee.HashMap<Element, Container.ElementSignalManager> ();
        add_command.connect ((c) => stack.add_command (c));
        errors = new Gee.PriorityQueue<Error> ((a, b) => {
            if (a.severity == b.severity) {
                return 0;
            } else if (a.severity == Severity.ERROR) {
                return -1;
            } else { // b.severity == Severity.ERROR
                return 1;
            }
        });
    }

    public Image (int width, int height, Element[] paths = {}) {
        setup_signals ();
        this._width = width;
        this._height = height;
        set_size (width, height);
        foreach (Element element in paths) {
            add_element (element);
        }
    }

    public Image.load (File file) {
        setup_signals ();
        // Set defaults for if an error occurs
        this._width = 16;
        this._height = 16;

        this._file = file;
        reload ();
    }

    public void reload () {
        var parser = new Xml.ParserCtxt ();
        var doc = parser.read_file (_file.get_path ());
        if (doc == null) {
            var xml_error = parser.get_last_error ();
            if (xml_error == null) {
                errors.offer (new Error (ErrorKind.CANT_READ, file.get_basename (), "Reading failed.", ""));
            } else if (xml_error->domain == 8) {
                errors.offer (new Error (ErrorKind.CANT_READ, file.get_basename (), xml_error->message, ""));
            } else {
                errors.offer (new Error (ErrorKind.INVALID_SVG, file.get_basename (), xml_error->message, ""));
            }

            error_available ();
            return;
        }

        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            var xml_error = parser.get_last_error ();
            var message = "No root element found.";
            if (xml_error != null) {
                message = xml_error->message;
            }

            errors.offer (new Error (ErrorKind.INVALID_SVG, file.get_basename (), message, ""));
            delete doc;
            error_available ();
            return;
        }

        if (root->name != "svg") {
            errors.offer (new Error (ErrorKind.INVALID_SVG, file.get_basename (), "Root element is not svg.\nActual element: '%s'".printf (root->name), ""));
            delete doc;
            error_available ();
            return;
        }

        string? width = null;
        string? height = null;

        for (var property = root->properties; property != null; property = property->next) {
            var content = ((Xml.Node*) property)->get_content ();
            switch (property->name) {
            case "width":
                width = content;
                break;
            case "height":
                height = content;
                break;
            case "version":
                // This should probably by checked eventually
                break;
            default:
                errors.offer (new Error.unknown_attribute ("svg", property->name, content));
                break;
            }
        }

        if (width == null) {
            // The real default is auto (= 100%), which is not supported
            errors.offer (new Error.missing_property ("svg", "width", "16"));
            this._width = 16;
        } else if (!int.try_parse (width, out this._width)) {
            errors.offer (new Error.invalid_property ("svg", "width", width, "16"));
            this._width = 16;
        }

        if (height == null) {
            // The real default is auto (= 100%), which is not supported
            errors.offer (new Error.missing_property ("svg", "height", "16"));
            this._height = 16;
        } else if (!int.try_parse (height, out this._height)) {
            errors.offer (new Error.invalid_property ("svg", "height", height, "16"));
            this._height = 16;
        }

        set_size (this.width, this.height);

        var patterns = new Gee.HashMap<string, Pattern> ();
        find_patterns (root, patterns);
        load_elements (root, patterns, errors);
        if (error != null) {
            error_available ();
        }
    }

    private void find_patterns (Xml.Node* root, Gee.Map<string, Pattern> patterns) {
        for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
            if (Pattern.can_load (iter->name)) {
                var pattern = Pattern.load_xml (iter, errors);
                if (pattern != null) {
                    var name = iter->get_prop ("id");
                    patterns.@set (name, pattern);
                }
            }

            find_patterns (iter, patterns);
        }
    }

    public File file {
        get {
            return _file;
        }
        set {
            _file = value;
            _name = _file.get_basename ();
            save_xml ();
        }
    }

    public Element? get_element (uint position) {
        return model.get_item (position) as Element;
    }

    public void draw (Cairo.Context cr) {
        applied_transform.apply (cr);
        draw_children (cr);
        cr.restore ();
    }

    public void draw_selection (Cairo.Context cr, double zoom) {
        applied_transform.apply (cr);
        draw_selected_child (cr, zoom);
        cr.restore ();
    }

    public void undo () {
        stack.undo ();
    }

    public void redo () {
        stack.redo ();
    }

    public void new_path () {
        var path = new Path ({ new PathSegment.line (width - 1.5, 1.5),
                               new PathSegment.line (width - 1.5, height - 1.5),
                               new PathSegment.line (1.5, height - 1.5),
                               new PathSegment.line (1.5, 1.5)},
                             {0.66f, 0.66f, 0.66f, 1f},
                             {0.33f, 0.33f, 0.33f, 1f},
                             "New Path");
        add_element (path);
        path.select (true);
    }

    public void new_circle () {
        var circle = new Circle (width / 2, height / 2, double.min (width, height) / 2 - 1,
                                 new Pattern.color ({0.66f, 0.66f, 0.66f, 1}),
                                 new Pattern.color ({0.33f, 0.33f, 0.33f, 1}));
        add_element (circle);
        circle.select (true);
    }

    public void new_rectangle () {
        var rectangle = new Rectangle (2.5, 2.5, width - 5, height - 5, new Pattern.color ({0.66f, 0.66f, 0.66f, 1}), new Pattern.color ({0.33f, 0.33f, 0.33f, 1}));
        add_element (rectangle);
        rectangle.select (true);
    }

    public void new_ellipse () {
        var ellipse = new Ellipse (width / 2, height / 2, width / 2 - 5, height / 2 - 5, new Pattern.color ({0.66f, 0.66f, 0.66f, 1}), new Pattern.color ({0.33f, 0.33f, 0.33f, 1}));
        add_element (ellipse);
        ellipse.select (true);
    }

    public void new_line () {
        var line = new Line (1.5, 1.5, width - 1.5, height - 1.5, new Pattern.color ({0.33f, 0.33f, 0.33f, 1}));
        add_element (line);
        line.select (true);
    }

    public void new_polyline () {
        var line = new Polyline ({Point (1.5, 1.5),
                                  Point (1.5, height - 1.5 ),
                                  Point (width - 1.5, 1.5 ),
                                  Point (width - 1.5, height - 1.5 )},
                                 new Pattern.color ({0.66f, 0.66f, 0.66f, 1}),
                                 new Pattern.color ({0.33f, 0.33f, 0.33f, 1}),
                                 "New Polyline");
        add_element (line);
        line.select (true);
    }

    public void new_polygon () {
        var shape = new Polygon ({Point (width / 2, 1.5),
                                  Point (1.5, height / 2 ),
                                  Point (width / 2, height - 1.5 ),
                                  Point (width - 1.5, height / 2 )},
                                 new Pattern.color ({0.66f, 0.66f, 0.66f, 1}),
                                 new Pattern.color ({0.33f, 0.33f, 0.33f, 1}),
                                 "New Polygon");
        add_element (shape);
        shape.select (true);
    }

    public void new_group () {
        var group = new Group ();
        add_element (group);
        group.select (true);
    }

    private void save_xml () {
        if (file == null) {
            print ("No file; not saving\n");
            return;
        }

        Xml.Doc* doc = new Xml.Doc ("1.0");
        Xml.Node* svg = new Xml.Node (null, "svg");
        doc->set_root_element (svg);
        svg->new_prop ("version", "1.1");
        svg->new_prop ("width", width.to_string ());
        svg->new_prop ("height", height.to_string ());
        svg->new_prop ("xmlns", "http://www.w3.org/2000/svg");

        Xml.Node* defs = new Xml.Node (null, "defs");
        svg->add_child (defs);

        save_children (svg, defs, 0);

        var res = doc->save_file (file.get_path ());
        if (res < 0) {
            // TODO: communicate error
            print ("Error saving file: %d\n", res);
            var err = Xml.get_last_error ();
            var message = "Saving failed.";
            if (err != null) {
                print ("Error: %d, %d: %s\n", err->domain, err->code, err->message);
                message = err->message;
            }

            errors.offer (new Error (ErrorKind.CANT_WRITE, file.get_basename (), message, ""));
            error_available ();
        }
    }

    public void begin (string prop) {
    }

    public void finish (string prop) {
    }

    public void cancel (string prop) {
    }

    public bool clicked_element (double x, double y, double tolerance, out Element? element, out Segment? segment, out Handle? handle) {
        double new_x, new_y, new_tolerance;
        applied_transform.update_point (x, y, out new_x, out new_y);
        applied_transform.update_distance (tolerance, out new_tolerance);
        Handle inner_handle;
        if (clicked_child (new_x, new_y, Math.sqrt ((tolerance * tolerance + new_tolerance * new_tolerance) / 2), out element, out segment, out inner_handle)) {
            if (inner_handle != null) {
                handle = new TransformedHandle ("Applied Transform", inner_handle, applied_transform);
            } else {
                handle = null;
            }

            return true;
        }

        handle = null;
        return false;
    }

    public bool clicked_control (double x, double y, double tolerance, out Handle? handle) {
        double new_x, new_y, new_tolerance;
        applied_transform.update_point (x, y, out new_x, out new_y);
        applied_transform.update_distance (tolerance, out new_tolerance);
        Handle inner_handle;
        if (clicked_handle (new_x, new_y, new_tolerance, out inner_handle)) {
            handle = new TransformedHandle ("Applied Transform", inner_handle, applied_transform);
            return true;
        }

        handle = null;
        return false;
    }
}
