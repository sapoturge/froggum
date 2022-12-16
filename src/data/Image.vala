public class Image : Gtk.TreeStore {
    private File _file;
    private CommandStack stack;

    public int width { get; private set; }
    public int height { get; private set; }

    public string name {
        get {
            return "Untitled";
        }
    }

    public signal void update ();

    public signal void path_selected (Element? path);

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
                ((Group) element).setup_draw (cr);
                Gtk.TreeIter inner_iter;
                iter_nth_child (out inner_iter, iter, iter_n_children (iter) - 1);
                do {
                    draw_element (cr, inner_iter);
                } while (iter_previous (ref inner_iter));
                ((Group) element).cleanup_draw (cr);
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

    private Gtk.TreeIter add_element(Element element, Gtk.TreeIter? root) {
        element.transform.width = width;
        element.transform.height = height;
        element.update.connect (() => { update (); });
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
                path_selected (element);
            } else if (selected == false) {
                selected_path = null;
                path_selected (null);
            }
        });
        Gtk.TreeIter iter;
        insert_with_values (out iter, root, 0, 0, element);
        element_index[element] = iter;
        if (already_loaded) {
            element.select (true);
        }
        update ();
        return iter;
    }

    public void new_path () {
        var path = new Path ({ new Segment.line (width - 1.5, 1.5),
                               new Segment.line (width - 1.5, height - 1.5),
                               new Segment.line (1.5, height - 1.5),
                               new Segment.line (1.5, 1.5)},
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

    public void new_group () {
        var group = new Group ();
        add_element (group, null);
    }

    public void duplicate_path () {
        var path = get_element (last_selected_path).copy ();
        add_element (path, null);
    }

    public void path_up () {
        Gtk.TreeIter next = selected_path;
        if (iter_next(ref next)) {
            swap (selected_path, next);
        }
    }

    public void path_down () {
        Gtk.TreeIter prev = selected_path;
        if (iter_previous(ref prev)) {
            swap (selected_path, prev);
        }
/* //
        int i;
        for (i = 1; i < paths.length; i++) {
            if (paths.index (i) == last_selected_path) {
                break;
            }
        }
        if (i == paths.length) {
            return;
        }
        paths.insert_val (i - 1, paths.remove_index (i));
        int[] indices = {};
        for (int j = 0; j < paths.length; j++) {
             indices += j;
        }
        indices [i] = i - 1;
        indices [i - 1] = i;
        rows_reordered (new Gtk.TreePath.first (), {0, this, null, null}, indices);
        last_selected_path.select (true);
        last_selected_path.select (false);
}*/
    }

    public void delete_path (Gtk.TreeIter? iter=null) {
        if (iter == null) {
            iter = last_selected_path;
        }
 
        if (iter != null) {
            if (iter == last_selected_path) {
                last_selected_path = null;
                selected_path = null;
                path_selected (null);
            }
            remove (ref iter);
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
/* //            
            var fill = "";
            var stroke = "";
            
            switch (path.fill.pattern_type) {
                case NONE:
                    fill = "none";
                    break;
                case COLOR:
                    fill = "rgba(%d,%d,%d,%f)".printf ((int) (path.fill.rgba.red*255), (int) (path.fill.rgba.green*255), (int) (path.fill.rgba.blue*255), path.fill.rgba.alpha);
                    break;
                case LINEAR:
                    pattern_index++;
                    fill = "url(#linearGrad%d)".printf (pattern_index);
                    Xml.Node* fill_element = new Xml.Node (null, "linearGradient");
                    fill_element->new_prop ("id", "linearGrad%d".printf (pattern_index));
                    fill_element->new_prop ("x1", path.fill.start.x.to_string ());
                    fill_element->new_prop ("y1", path.fill.start.y.to_string ());
                    fill_element->new_prop ("x2", path.fill.end.x.to_string ());
                    fill_element->new_prop ("y2", path.fill.end.y.to_string ());
                    fill_element->new_prop ("gradientUnits", "userSpaceOnUse");
                    
                    for (int j = 0; j < path.fill.get_n_items (); j++) {
                        var stop = (Stop) path.fill.get_item (j);
                        Xml.Node* stop_element = new Xml.Node (null, "stop");
                        stop_element->new_prop ("offset", stop.offset.to_string ());
                        stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                        stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                        fill_element->add_child (stop_element);
                    }
                    
                    defs->add_child (fill_element);
                    break;
                case RADIAL:
                    pattern_index++;
                    fill = "url(#radialGrad%d)".printf (pattern_index);
                    Xml.Node* fill_element = new Xml.Node (null, "radialGradient");
                    fill_element->new_prop ("id", "radialGrad%d".printf (pattern_index));
                    fill_element->new_prop ("cx", path.fill.start.x.to_string ());
                    fill_element->new_prop ("cy", path.fill.start.y.to_string ());
                    fill_element->new_prop ("fx", path.fill.start.x.to_string ());
                    fill_element->new_prop ("fy", path.fill.start.y.to_string ());
                    fill_element->new_prop ("r", Math.hypot (path.fill.end.x - path.fill.start.x, path.fill.end.y - path.fill.start.y).to_string ());
                    fill_element->new_prop ("fr", "0");
                    fill_element->new_prop ("gradientUnits", "userSpaceOnUse");
                    
                    for (int j = 0; j < path.fill.get_n_items (); j++) {
                        var stop = (Stop) path.fill.get_item (j);
                        Xml.Node* stop_element = new Xml.Node (null, "stop");
                        stop_element->new_prop ("offset", stop.offset.to_string ());
                        stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                        stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                        fill_element->add_child (stop_element);
                    }
                    
                    defs->add_child (fill_element);
                    break;
            }
            
            switch (path.stroke.pattern_type) {
                case NONE:
                    stroke = "none";
                    break;
                case COLOR:
                    stroke = "rgba(%d,%d,%d,%f)".printf ((int) (path.stroke.rgba.red*255), (int) (path.stroke.rgba.green*255), (int) (path.stroke.rgba.blue*255), path.stroke.rgba.alpha);
                    break;
                case LINEAR:
                    pattern_index++;
                    stroke = "url(#linearGrad%d)".printf (pattern_index);
                    Xml.Node* stroke_element = new Xml.Node (null, "linearGradient");
                    stroke_element->new_prop ("id", "linearGrad%d".printf (pattern_index));
                    stroke_element->new_prop ("x1", path.stroke.start.x.to_string ());
                    stroke_element->new_prop ("y1", path.stroke.start.y.to_string ());
                    stroke_element->new_prop ("x2", path.stroke.end.x.to_string ());
                    stroke_element->new_prop ("y2", path.stroke.end.y.to_string ());
                    stroke_element->new_prop ("gradientUnits", "userSpaceOnUse");
                    
                    for (int j = 0; j < path.stroke.get_n_items (); j++) {
                        var stop = (Stop) path.stroke.get_item (j);
                        Xml.Node* stop_element = new Xml.Node (null, "stop");
                        stop_element->new_prop ("offset", stop.offset.to_string ());
                        stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                        stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                        stroke_element->add_child (stop_element);
                    }
                    
                    defs->add_child (stroke_element);
                    break;
                case RADIAL:
                    pattern_index++;
                    stroke = "url(#radialGrad%d)".printf (pattern_index);
                    Xml.Node* stroke_element = new Xml.Node (null, "radialGradient");
                    stroke_element->new_prop ("id", "radialGrad%d".printf (pattern_index));
                    stroke_element->new_prop ("cx", path.stroke.start.x.to_string ());
                    stroke_element->new_prop ("cy", path.stroke.start.y.to_string ());
                    stroke_element->new_prop ("fx", path.stroke.start.x.to_string ());
                    stroke_element->new_prop ("fy", path.stroke.start.y.to_string ());
                    stroke_element->new_prop ("r", Math.hypot (path.stroke.end.x - path.stroke.start.x, path.stroke.end.y - path.stroke.start.y).to_string ());
                    stroke_element->new_prop ("fr", "0");
                    stroke_element->new_prop ("gradientUnits", "userSpaceOnUse");
                    
                    for (int j = 0; j < path.stroke.get_n_items (); j++) {
                        var stop = (Stop) path.stroke.get_item (j);
                        Xml.Node* stop_element = new Xml.Node (null, "stop");
                        stop_element->new_prop ("offset", stop.offset.to_string ());
                        stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                        stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                        stroke_element->add_child (stop_element);
                    }
                    
                    defs->add_child (stroke_element);
                    break;
            }
            
            Xml.Node* element = new Xml.Node (null, "path");
            
            element->new_prop ("id", path.title);
            element->new_prop ("fill", fill);
            element->new_prop ("stroke", stroke);
            element->new_prop ("d", path.to_string ());
            svg->add_child (element);
}*/
        
}
