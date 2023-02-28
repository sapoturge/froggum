public struct ElementIter {
    Gtk.TreeIter iter;
    Element element;

    public ElementIter (Gtk.TreeIter iter, Element element) {
        this.iter = iter;
        this.element = element;
    }
}

public class Image : Gtk.TreeStore, Undoable {
    private File _file;
    private CommandStack stack;

    public int width { get; private set; }
    public int height { get; private set; }

    public string name {
        get {
            return "Untitled";
        }
    }

    public ElementIter item {
        set {
            get_element (value.iter).select (false);
            set_value (value.iter, 0, value.element);
            element_index[value.element] = value.iter;
            value.element.select (true);
            update ();
        }
    }

    public signal void update ();

    public signal void path_selected (Element? path, Gtk.TreeIter? iter);

    private Gee.HashMap<Element, Gtk.TreeIter?> element_index;

    private Gtk.TreeIter? selected_path;
    private Gtk.TreeIter? last_selected_path;
    
    private uint save_id;
    private bool already_loaded = false;

    private void setup_signals () {
        update.connect (() => {
            if (save_id != 0) {
                Source.remove (save_id);
            }
            
            save_id = Timeout.add (100, () => {
                save_id = 0;
                save_xml ();
                return false;
            });
        });

        row_inserted.connect ((path, iter) => {
            Element? element = get_element(iter);
            if (element != null) {
                element_index[element] = iter;
            }
        });

        row_changed.connect ((path, iter) => {
            Element? element = get_element(iter);
            if (element != null) {
                element_index[element] = iter;
            }
        });
    }
    
    construct {
        stack = new CommandStack ();
        set_column_types ({typeof (Element)});

        element_index = new Gee.HashMap<Element, Gtk.TreeIter?> ();
    }

    public Image (int width, int height, Element[] paths = {}) {
        setup_signals ();
        this.width = width;
        this.height = height;
        this.selected_path = null;
        foreach (Element element in paths) {
            add_element (element, null);
        }
        already_loaded = true;
    }

    public Image.load (File file) {
        setup_signals ();
        this._file = file;
        var doc = Xml.Parser.parse_file (file.get_path ());
        if (doc == null) {
            // Mark for error somehow: Could not open file
            this.width = 16;
            this.height = 16;
            setup_signals ();
            return;
        }
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            // Mark for error again: Empty file
            delete doc;
            this.width = 16;
            this.height = 16;
            setup_signals ();
            return;
        }
        if (root->name == "svg") {
            this.width = int.parse (root->get_prop ("width"));
            this.height = int.parse (root->get_prop ("height"));
            
            var patterns = new Gee.HashMap<string, Pattern> ();

            for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
                if (iter->name == "defs") {
                    for (Xml.Node* def = iter->children; def != null; def = def->next) {
                        if (def->name == "linearGradient") {
                            var name = def->get_prop ("id");
                            var x1 = double.parse (def->get_prop ("x1"));
                            var y1 = double.parse (def->get_prop ("y1"));
                            var x2 = double.parse (def->get_prop ("x2"));
                            var y2 = double.parse (def->get_prop ("y2"));
                            var pattern = new Pattern.linear ({x1, y1}, {x2, y2});
                            
                            for (Xml.Node* stop = def->children; stop != null; stop = stop->next) {
                                var offset_data = stop->get_prop ("offset");
                                double offset;
                                if (offset_data == null) {
                                    offset = 0;
                                } else if (offset_data.has_suffix ("%")) {
                                    offset = double.parse (offset_data.substring (0, offset_data.length - 1)) / 100;
                                } else {
                                    offset = double.parse (offset_data);
                                }
                                var color = process_color (stop->get_prop ("stop-color") ?? "#000");
                                var opacity = stop->get_prop ("stop-opacity");
                                if (opacity != null) {
                                    if (opacity.has_suffix ("%")) {
                                        color.alpha = double.parse (opacity.substring (0, opacity.length - 1)) / 100;
                                    } else {
                                        color.alpha = double.parse (opacity);
                                    }
                                }
                                pattern.add_stop (new Stop (offset, color));
                            }
                            
                            patterns.@set (name, pattern);
                        } else if (def->name == "radialGradient") {
                            var name = def->get_prop ("id");
                            var cx = double.parse (def->get_prop ("cx"));
                            var cy = double.parse (def->get_prop ("cy"));
                            var r = double.parse (def->get_prop ("r"));
                            var pattern = new Pattern.radial ({cx, cy}, {cx + r, cy});
                            
                            for (Xml.Node* stop = def->children; stop != null; stop = stop->next) {
                                if (stop->name == "stop") {
                                    var offset_data = stop->get_prop ("offset");
                                    double offset;
                                    if (offset_data == null) {
                                        offset = 0;
                                    } else if (offset_data.has_suffix ("%")) {
                                        offset = double.parse (offset_data.substring (0, offset_data.length - 1)) / 100;
                                    } else {
                                        offset = double.parse (offset_data);
                                    }
                                    var color = process_color (stop->get_prop ("stop-color") ?? "#000");
                                    var opacity = stop->get_prop ("stop-opacity");
                                    if (opacity != null) {
                                        if (opacity.has_suffix ("%")) {
                                            color.alpha = double.parse (opacity.substring (0, opacity.length - 1)) / 100;
                                        } else {
                                            color.alpha = double.parse (opacity);
                                        }
                                    }
                                    pattern.add_stop (new Stop (offset, color));
                                }
                            }
                            
                            patterns.@set (name, pattern);
                        }
                    }
                }
            }

            load_elements (root, patterns, null);
        }
        already_loaded = true;
    }

    private void load_elements (Xml.Node* group, Gee.HashMap<string, Pattern> patterns, Gtk.TreeIter? root) {
        for (Xml.Node* iter = group->children; iter != null; iter = iter->next) {
            if (iter->name == "path") {
                var path = new Path.from_xml (iter, patterns);
                add_element (path, root);
            } else if (iter->name == "circle") {
                var circle = new Circle.from_xml (iter, patterns);
                add_element (circle, root);
            } else if (iter->name == "g") {
                var g = new Group.from_xml (iter, patterns);
                load_elements (iter, patterns, add_element (g, root));
            } else if (iter->name == "rect") {
                var rect = new Rectangle.from_xml (iter, patterns);
                add_element (rect, root);
            } else if (iter->name == "ellipse") {
                var ellipse = new Ellipse.from_xml (iter, patterns);
                add_element (ellipse, root);
            } else if (iter->name == "line") {
                var line = new Line.from_xml (iter, patterns);
                add_element (line, root);
            } else if (iter->name == "polyline") {
                var line = new Polyline.from_xml (iter, patterns);
                add_element (line, root);
            } else if (iter->name == "polygon") {
                var polygon = new Polygon.from_xml (iter, patterns);
                add_element (polygon, root);
            }
        }
    }
                
    private Gdk.RGBA process_color (string color) {
        var rgba = Gdk.RGBA ();
        if (color.has_prefix ("rgb(")) {
            var channels = color.substring (4, color.length - 5).split (",");
            rgba.red = int.parse (channels[0]) / 255.0;
            rgba.green = int.parse (channels[1]) / 255.0;
            rgba.blue = int.parse (channels[2]) / 255.0;
        } else if (color.has_prefix ("rgba(")) {
            var channels = color.substring (5, color.length - 6).split (",");
            rgba.red = int.parse (channels[0]) / 255.0;
            rgba.green = int.parse (channels[1]) / 255.0;
            rgba.blue = int.parse (channels[2]) / 255.0;
            rgba.alpha = double.parse (channels[3]);
        } else if (color.has_prefix ("#")) {
            var color_length = (color.length - 1) / 3;
            color.substring (1, color_length).scanf ("%x", &rgba.red);
            color.substring (1 + color_length, color_length).scanf ("%x", &rgba.green);
            color.substring (1 + 2 * color_length, color_length).scanf ("%x", &rgba.blue);
        }
        return rgba;
    }

    public File file {
        get {
            return _file;
        }
        set {
            _file = value;
            save_xml ();
        }
    }

    public Element? get_element (Gtk.TreeIter iter) {
        Value element;
	get_value (iter, 0, out element);
        return ((Element*) (element.peek_pointer ()));
    }

    public void draw (Cairo.Context cr) {
        if (iter_n_children (null) > 0) {
            Gtk.TreeIter iter;
            iter_nth_child (out iter, null, iter_n_children (null) - 1);
            do {
                draw_element (cr, iter);
            } while (iter_previous (ref iter));
        }
    }

    public void draw_element (Cairo.Context cr, Gtk.TreeIter iter) {
        var element = get_element (iter);
        element.transform.apply (cr);
        if (element is Group && element.visible) {
            if (iter_has_child (iter)) {
                Gtk.TreeIter inner_iter;
                iter_nth_child (out inner_iter, iter, iter_n_children (iter) - 1);
                do {
                    draw_element (cr, inner_iter);
                } while (iter_previous (ref inner_iter));
            }
        } else {
            element.draw (cr);
        }
        cr.restore ();
    }
    
    public void undo () {
        stack.undo ();
    }
    
    public void redo () {
        stack.redo ();
    }

    private Gtk.TreeIter add_element (Element element, Gtk.TreeIter? root, Gtk.TreeIter? iter = null) {
        setup_element_signals (element);
        insert_with_values (out iter, root, 0, 0, element);
        element_index[element] = iter;
        if (already_loaded) {
            element.select (true);
        }
        update ();
        return iter;
    }

    private void setup_element_signals (Element element) {
        element.transform.width = width;
        element.transform.height = height;
        element.update.connect (() => { update (); });
        element.request_delete.connect (() => {
            element.select (false);
            delete_path (element_index[element]);
        });
        element.select.connect ((selected) => {
            Element? select_path;
            if (selected_path != null) {
                select_path = get_element (selected_path);
            } else {
                select_path = null;
            }
            if (element != select_path) {
                if (select_path != null) {
                    select_path.select (false);
                }
                last_selected_path = element_index[element];
                selected_path = element_index[element];
                path_selected (element, selected_path);
            } else if (selected == false) {
                selected_path = null;
                path_selected (null, null);
            }
        });
        element.add_command.connect ((c) => {
            stack.add_command (c);
        });
        element.replace.connect ((o, n) => {
            setup_element_signals (n);
            o.select (false);
            var iter = element_index[o];
            element_index[n] = iter;
            set_value (iter, 0, n);
            n.select (true);
            update ();
            var old_iter = ElementIter (iter, o);
            var new_iter = ElementIter (iter, n);
            var command = new Command ();
            command.add_value (this, "item", new_iter, old_iter);
            stack.add_command (command);
        });
    }

    public void new_path () {
        var path = new Path ({ new PathSegment.line (width - 1.5, 1.5),
                               new PathSegment.line (width - 1.5, height - 1.5),
                               new PathSegment.line (1.5, height - 1.5),
                               new PathSegment.line (1.5, 1.5)},
                             {0.66, 0.66, 0.66, 1},
                             {0.33, 0.33, 0.33, 1},
                             "New Path");
        add_element (path, null);
    }

    public void new_circle () {
        var circle = new Circle (width / 2, height / 2, double.min (width, height) / 2 - 1,
                                 new Pattern.color ({0.66, 0.66, 0.66, 1}),
                                 new Pattern.color ({0.33, 0.33, 0.33, 1}));
        add_element (circle, null);
    }

    public void new_rectangle () {
        var rectangle = new Rectangle (2.5, 2.5, width - 5, height - 5, new Pattern.color ({0.66, 0.66, 0.66, 1}), new Pattern.color ({0.33, 0.33, 0.33, 1}));
        add_element (rectangle, null);
    }

    public void new_ellipse () {
        var ellipse = new Ellipse (width / 2, height / 2, width / 2 - 5, height / 2 - 5, new Pattern.color ({0.66, 0.66, 0.66, 1}), new Pattern.color ({0.33, 0.33, 0.33, 1}));
        add_element (ellipse, null);
    }

    public void new_line () {
        var line = new Line (1.5, 1.5, width - 1.5, height - 1.5, new Pattern.color ({0.33, 0.33, 0.33, 1}));
        add_element (line, null);
    }

    public void new_polyline () {
        var line = new Polyline ({Point (1.5, 1.5),
                                  Point (1.5, height - 1.5 ),
                                  Point (width - 1.5, 1.5 ),
                                  Point (width - 1.5, height - 1.5 )},
                                 new Pattern.color ({0.66, 0.66, 0.66, 1}),
                                 new Pattern.color ({0.33, 0.33, 0.33, 1}),
                                 "New Polyline");
        add_element (line, null);
    }

    public void new_polygon () {
        var shape = new Polygon ({Point (width / 2, 1.5),
                                  Point (1.5, height / 2 ),
                                  Point (width / 2, height - 1.5 ),
                                  Point (width - 1.5, height / 2 )},
                                 new Pattern.color ({0.66, 0.66, 0.66, 1}),
                                 new Pattern.color ({0.33, 0.33, 0.33, 1}),
                                 "New Polygon");
        add_element (shape, null);
    }

    public void new_group () {
        var group = new Group ();
        add_element (group, null);
    }

    public void duplicate_path (Gtk.TreeIter? iter=null) {
        if (iter == null) {
            iter = last_selected_path;
        }
 
        if (iter != null) {
            if (iter == last_selected_path) {
                last_selected_path = null;
                selected_path = null;
                path_selected (null, null);
            }

            var path = get_element (iter).copy ();
            add_element (path, null);
            update ();
        }
    }

    public void path_up (Gtk.TreeIter? iter=null) {
        if (iter == null) {
            iter = last_selected_path;
        }
 
        if (iter != null) {
            if (iter == last_selected_path) {
                last_selected_path = null;
                selected_path = null;
                path_selected (null, null);
            }

            Gtk.TreeIter prev = iter;

            if (iter_next(ref prev)) {
                swap (iter, prev);
            }

            update ();
       }
    }

    public void path_down (Gtk.TreeIter? iter=null) {
        if (iter == null) {
            iter = last_selected_path;
        }
 
        if (iter != null) {
            if (iter == last_selected_path) {
                last_selected_path = null;
                selected_path = null;
                path_selected (null, null);
            }

            Gtk.TreeIter next = iter;
            if (iter_previous(ref next)) {
                swap (iter, next);
            }

            update ();
       }
    }

    public void delete_path (Gtk.TreeIter? iter=null) {
        if (iter == null) {
            iter = last_selected_path;
        }
 
        if (iter != null) {
            if (iter == selected_path) {
                path_selected (null, null);
                selected_path = null;
            }

            remove (ref iter);

            if (iter == last_selected_path) {
                last_selected_path = null;
            }

            update ();
       }
    }

    private void save_xml () {
        if (file == null) {
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
        
        save_children (svg, defs, 0, null);

        var res = doc->save_file (file.get_path ());
        if (res < 0) {
            // TODO: communicate error
        }
    }

    private int save_children(Xml.Node* root_node, Xml.Node* defs, int pattern_index, Gtk.TreeIter? root) {
        Gtk.TreeIter iter;
        var n_children = iter_n_children (root);
        if (n_children != 0) {
            iter_nth_child (out iter, root, n_children - 1);
            do {
                var path = get_element (iter);
                Xml.Node* node;
                pattern_index = path.add_svg(root_node, defs, pattern_index, out node);
                if (path is Group) {
                    pattern_index = save_children(node, defs, pattern_index, iter);
                }
            } while (iter_previous (ref iter));
        }
        return pattern_index;
    }

    public void begin (string prop, Value? start = null) {
    }

    public void finish (string prop) {
    }
}
