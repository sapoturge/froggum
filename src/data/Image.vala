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

    // private Array<Element> paths;

    private Gtk.TreeIter? selected_path;
    private Gtk.TreeIter? last_selected_path;
    
    private uint save_id;

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
    }
    
    construct {
        stack = new CommandStack ();
        set_column_types ({typeof (Element)});
    }

    public Image (int width, int height, Element[] paths = {}) {
        this.width = width;
        this.height = height;
        this.selected_path = null;
        foreach (Element element in paths) {
            add_element (element);
        }
        setup_signals ();
    }

    public Image.load (File file) {
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
                if (iter->name == "path") {
                    var fill = new Pattern.none ();
                    var stroke = new Pattern.none ();
                    var name = iter->get_prop ("id");
                    if (name == null) {
                        name = "Path";
                    }
                    var style = iter->get_prop ("style");
                    if (style != null) {
                        var styles = style.split (";");
                        int fill_red = 0;
                        int fill_green = 0;
                        int fill_blue = 0;
                        float fill_alpha = 0;
                        int stroke_red = 0;
                        int stroke_green = 0;
                        int stroke_blue = 0;
                        float stroke_alpha = 0;
                        foreach (string s in styles) {
                            if (s.has_prefix ("fill:#")) {
                                var color = s.substring (6);
                                var r = color.substring (0, color.length / 3);
                                var g = color.substring (r.length, r.length);
                                var b = color.substring (r.length * 2, r.length);
                                r.scanf ("%x", &fill_red);
                                g.scanf ("%x", &fill_green);
                                b.scanf ("%x", &fill_blue);
                            } else if (s.has_prefix ("stroke:#")) {
                                var color = s.substring (8);
                                var r = color.substring (0, color.length / 3);
                                var g = color.substring (r.length, r.length);
                                var b = color.substring (r.length * 2, r.length);
                                r.scanf ("%x", &stroke_red);
                                g.scanf ("%x", &stroke_green);
                                b.scanf ("%x", &stroke_blue);
                            } else if (s.has_prefix ("fill-opacity:")) {
                                var op = s.substring (13);
                                op.scanf ("%f", &fill_alpha);
                            } else if (s.has_prefix ("stroke-opacity:")) {
                                var op = s.substring (15);
                                op.scanf ("%f", &stroke_alpha);
                            }
                        }
                        fill = new Pattern.color ({fill_red / 255.0, fill_green / 255.0, fill_blue / 255.0, fill_alpha});
                        stroke = new Pattern.color ({stroke_red / 255.0, stroke_green / 255.0, stroke_blue / 255.0, stroke_alpha});
                    }
                    var fill_data = iter->get_prop ("fill");
                    if (fill_data != null) {
                        if (fill_data.has_prefix ("url(#")) {
                            fill = patterns.@get (fill_data.substring (5, fill_data.length - 6));
                        } else if (fill_data == "none") {
                            fill = new Pattern.none ();
                        } else {
                            fill = new Pattern.color (process_color (fill_data));
                        }
                    }
                    var stroke_data = iter->get_prop ("stroke");
                    if (stroke_data != null) {
                        if (stroke_data.has_prefix ("url(#")) {
                            stroke = patterns.@get (stroke_data.substring (5, stroke_data.length - 6));
                        } else if (stroke_data == "none") {
                            stroke = new Pattern.none ();
                        } else {
                            stroke = new Pattern.color (process_color (stroke_data));
                        }
                    }
                    var data = iter->get_prop ("d");
                    var path = new Path.from_string_with_pattern (data, fill, stroke, name);
                    add_element (path);
                } else if (iter->name == "defs") {
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
        }
        
        setup_signals ();
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

    public Element get_element (Gtk.TreeIter iter) {
        Value element;
	get_value (iter, 0, out element);
        return ((Element*) (element.peek_pointer ()));
    }

    public void draw (Cairo.Context cr) {
        Gtk.TreeIter iter;
        if (get_iter_first (out iter)) {
            do {
                draw_element (cr, iter);
            } while (iter_next (ref iter));
        }
    }

    private void draw_element (Cairo.Context cr, Gtk.TreeIter iter) {
        var element = get_element (iter);
        if (element is Group) {
            (element as Group).setup_draw (cr);
            Gtk.TreeIter inner_iter;
            if (iter_children (out inner_iter, iter)) {
                do {
                    draw_element (cr, inner_iter);
                } while (iter_next (ref inner_iter));
            }
            (element as Group).cleanup_draw (cr);
        } else {
            element.draw (cr);
        }
    }
    
    public void undo () {
        stack.undo ();
    }
    
    public void redo () {
        stack.redo ();
    }

    private void add_element(Element element) {
        element.update.connect (() => { update (); });
        element.select.connect ((selected) => {
            Element? select_path;
            if (selected_path != null) {
                select_path = get_element (selected_path);
            } else {
                select_path = null;
            }
            if (element != select_path) {
                select_path.select (false);
                // last_selected_path = element;
                // select_path = element;
                path_selected (element);
            } else if (selected == false) {
                selected_path = null;
                path_selected (null);
            }
        });
        Gtk.TreeIter iter;
        insert_with_values (out iter, null, 0, 0, element);
        element.select (true);
        update ();
    }

    public void new_path () {
        var path = new Path ({ new Segment.line (width - 1.5, 1.5),
                               new Segment.line (width - 1.5, height - 1.5),
                               new Segment.line (1.5, height - 1.5),
                               new Segment.line (1.5, 1.5)},
                             {0.66, 0.66, 0.66, 1},
                             {0.33, 0.33, 0.33, 1},
                             "New Path");
        add_element (path);
    }

    public void new_circle () {
        var circle = new Circle (width / 2, height / 2, double.min (width, height) / 2 - 1,
                                 new Pattern.color ({0.66, 0.66, 0.66, 1}),
                                 new Pattern.color ({0.33, 0.33, 0.33, 1}));
        add_element (circle);
    }

    public void new_group () {
        var group = new Group ();
        add_element (group);
    }

    public void duplicate_path () {
        var path = get_element (last_selected_path).copy ();
        add_element (path);
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
/*
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
*/
    }

    public void delete_path () {
        remove (ref selected_path);
/*
        int i;
        for (i = 0; i < paths.length; i++) {
            if (paths.index (i) == last_selected_path) {
                break;
            }
        }
        if (selected_path != null) {
            selected_path.select (false);
        }
        paths.remove_index (i);
        row_deleted (new Gtk.TreePath.from_indices (i));
        if (i > 0) {
            paths.index (i - 1).select (true);
        } else {
            paths.index (0).select (true);
        }
*/
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
        
        var pattern_index = 0;
        
        Gtk.TreeIter iter;
        for (iter_children (out iter, null); iter_next (ref iter);) {
            var path = get_element (iter);
            pattern_index = path.add_svg (svg, defs, pattern_index);
/*            
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
*/
        }
        
        var res = doc->save_file (file.get_path ());
        if (res < 0) {
            // TODO: communicate error
        }
    }
}
