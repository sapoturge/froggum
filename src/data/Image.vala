public class Image : Object, Undoable, Updatable, Transformed, Container {
    private File _file;
    private CommandStack stack;

    public int width { get; private set; }
    public int height { get; private set; }
    public Error error { get; private set; }

    private string? _name;
    public string name {
        get {
            return _name ?? "Untitled";
        }
    }

    public override Gtk.TreeListModel tree { get; set; }
    public override Element? selected_child { get; set; }
    public Transform transform { get; set; }

    protected Gee.Map<Element, Container.ElementSignalManager> signal_managers { get; set; }

    private uint save_id;
    private bool already_loaded = false;

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
                if (error.severity == Severity.NO_ERROR) {
                    save_xml ();
                }
                return false;
            });
        });
    }
    
    construct {
        transform = new Transform.identity ();
        stack = new CommandStack ();
        var model = new ListStore (typeof (Element));
        this.tree = new Gtk.TreeListModel (model, false, false, get_children);
        signal_managers = new Gee.HashMap<Element, Container.ElementSignalManager> ();
        add_command.connect ((c) => stack.add_command (c));
    }

    public Image (int width, int height, Element[] paths = {}) {
        setup_signals ();
        this.width = width;
        this.height = height;
        set_size (width, height);
        foreach (Element element in paths) {
            add_element (element);
        }
        already_loaded = true;
    }

    public Image.load (File file) {
        setup_signals ();
        this._file = file;
        var parser = new Xml.ParserCtxt ();
        var doc = parser.read_file (file.get_path ());
        if (doc == null) {
            var xml_error = parser.get_last_error ();
            if (xml_error == null || xml_error->domain == 8) {
                error = new Error (ErrorKind.CANT_READ, file.get_basename ());
            } else {
                error = new Error (ErrorKind.INVALID_SVG, file.get_basename ());
            }

            this.width = 16;
            this.height = 16;
            setup_signals ();
            return;
        }
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            error = new Error (ErrorKind.INVALID_SVG, file.get_basename ());
            delete doc;
            this.width = 16;
            this.height = 16;
            setup_signals ();
            return;
        }
        if (root->name == "svg") {
            this.width = int.parse (root->get_prop ("width"));
            this.height = int.parse (root->get_prop ("height"));
            set_size (this.width, this.height);
            
            var patterns = new Gee.HashMap<string, Pattern> ();

            for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
                if (iter->name == "defs") {
                    for (Xml.Node* def = iter->children; def != null; def = def->next) {
                        var pattern = Pattern.load_xml (def);
                        if (pattern != null) {
                            var name = def->get_prop ("id");
                            patterns.@set (name, pattern);
                        }
                    }
                }
            }

            load_elements (root, patterns);
        }
        already_loaded = true;
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
        draw_children (cr);
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
            if (err != null) {
                print ("Error: %d, %d: %s\n", err->domain, err->code, err->message);
            }
        }
    }

    public void begin (string prop) {
    }

    public void finish (string prop) {
    }

    public void cancel (string prop) {
    }
}
