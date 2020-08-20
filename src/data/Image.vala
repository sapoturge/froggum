public class Image : Object, ListModel {
    private File _file;

    public int width { get; private set; }
    public int height { get; private set; }

    public string name {
        get {
            return "Untitled";
        }
    }

    public signal void update ();

    public signal void path_selected (Path? path);

    private Array<Path> paths;

    private Path selected_path;
    private Path last_selected_path;
    
    private uint save_id;

    private void setup_signals () {
        for (int i = 0; i < paths.length; i++) {
            var path = paths.index (i);
            path.update.connect (() => { update (); });
            path.select.connect ((selected) => {
                if (selected && path != selected_path) {
                    selected_path.select (false);
                    last_selected_path = path;
                    selected_path = path;
                    path_selected (path);
                } else if (selected == false) {
                    selected_path = null;
                    path_selected (null);
                }
            });
        }
        
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

    public Image (int width, int height, Path[] paths = {}) {
        this.width = width;
        this.height = height;
        this.paths = new Array<Path> ();
        this.paths.append_vals(paths, paths.length);
        this.selected_path = null;
        setup_signals ();
    }

    public Image.load (File file) {
        this.paths = new Array<Path> ();
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

            for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
                if (iter->name == "path") {
                    Gdk.RGBA fill;
                    Gdk.RGBA stroke;
                    var name = iter->get_prop ("id");
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
                        fill = {fill_red / 255.0, fill_green / 255.0, fill_blue / 255.0, fill_alpha};
                        stroke = {stroke_red / 255.0, stroke_green / 255.0, stroke_blue / 255.0, stroke_alpha};
                    } else {
                        fill = {0.66, 0.66, 0.66, 1};
                        stroke = {0.33, 0.33, 0.33, 1};
                    }
                    var data = iter->get_prop ("d");
                    paths.append_val(new Path.from_string (data, fill, stroke, name));
                }
            }
        }
        setup_signals ();
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

    public Object? get_item (uint position) {
        if (position < paths.length) {
            return paths.index(paths.length-position-1);
        }
        return null;
    }

    public Type get_item_type () {
        return typeof (Path);
    }

    public uint get_n_items () {
        return paths.length;
    }

    public void draw (Cairo.Context cr) {
        for (int i = 0; i < paths.length; i++) {
            paths.index (i).draw (cr);
        }
    }

    public Path[] get_paths () {
        return paths.data;
    }

    public void new_path () {
        var path = new Path ({ new Segment.line (width - 1.5, 1.5),
                               new Segment.line (width - 1.5, height - 1.5),
                               new Segment.line (1.5, height - 1.5),
                               new Segment.line (1.5, 1.5)},
                             {0.66, 0.66, 0.66, 1},
                             {0.33, 0.33, 0.33, 1},
                             "New Path");
        path.update.connect (() => { update (); });
        path.select.connect ((selected) => {
            if (path != selected_path) {
                selected_path.select (false);
                last_selected_path = path;
                selected_path = path;
                path_selected (path);
            } else if (selected == false) {
                selected_path = null;
                path_selected (null);
            }
        });
        paths.append_val (path);
        items_changed (0, 0, 1);
        path.select (true);
        update ();
    }

    public void duplicate_path () {
        var path = last_selected_path.copy ();
        path.update.connect (() => { update (); });
        path.select.connect ((selected) => {
            if (path != selected_path) {
                selected_path.select (false);
                last_selected_path = path;
                selected_path = path;
                path_selected (path);
            } else if (selected == false) {
                selected_path = null;
                path_selected (null);
            }
        });
        paths.append_val (path);
        items_changed (0, 0, 1);
        path.select (true);
        update ();
    }

    public void path_up () {
        int i;
        for (i = 0; i < paths.length - 1; i++) {
            if (paths.index (i) == last_selected_path) {
                break;
            }
        }
        if (i == paths.length - 1) {
            return;
        }
        paths.insert_val (i + 1, paths.remove_index (i));
        items_changed (paths.length - i - 2, 2, 2);
        last_selected_path.select (true);
        last_selected_path.select (false);
    }

    public void path_down () {
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
        items_changed (paths.length - i - 1, 2, 2);
        last_selected_path.select (true);
        last_selected_path.select (false);
    }

    public void delete_path () {
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
        items_changed (paths.length - i, 1, 0);
        if (i > 0) {
            paths.index (i - 1).select (true);
        } else {
            paths.index (0).select (true);
        }
    }

    private async void save () {
        if (file == null) {
            return;
        }
        try {
            var stream = yield file.replace_async (null, true, FileCreateFlags.NONE);
            size_t written = 0;
            yield stream.write_all_async ("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n".data, 0, null, out written);
            yield stream.write_all_async ("<svg version=\"1.1\" width=\"%d\" height=\"%d\">\n".printf (width, height).data, 0, null, out written);
            for (int i = 0; i < paths.length; i++) {
                var path = paths.index (i);
                yield stream.write_all_async ("<path id=\"%s\" style=\"fill:#".printf (path.title).data, 0, null, out written);
                yield stream.write_all_async ("%02x%02x%02x".printf ((uint) (path.fill.rgba.red * 255),
                                                         (uint) (path.fill.rgba.green * 255),
                                                         (uint) (path.fill.rgba.blue * 255)).data, 0, null, out written);
                yield stream.write_all_async (";stroke:#".data, 0, null, out written);
                yield stream.write_all_async ("%02x%02x%02x".printf ((uint) (path.stroke.rgba.red * 255),
                                                         (uint) (path.stroke.rgba.green * 255),
                                                         (uint) (path.stroke.rgba.blue * 255)).data, 0, null, out written);
                yield stream.write_all_async (";fill-opacity:%f;stroke-opacity:%f".printf (path.fill.rgba.alpha, path.stroke.rgba.alpha).data, 0, null, out written);
                yield stream.write_all_async ("\" d=\"".data, 0, null, out written);
                yield stream.write_all_async ("M %f %f ".printf (path.root_segment.start.x, path.root_segment.start.y).data, 0, null, out written);
                var s = path.root_segment;
                var first = true;
                while (first || s != path.root_segment) {
                    first = false;
                    switch (s.segment_type) {
                        case SegmentType.LINE:
                            yield stream.write_all_async ("L %f %f ".printf (s.end.x, s.end.y).data, 0, null, out written);
                            break;
                        case SegmentType.CURVE:
                            yield stream.write_all_async ("C %f %f %f %f %f %f ".printf (s.p1.x, s.p1.y, s.p2.x, s.p2.y, s.end.x, s.end.y).data, 0, null, out written);
                            break;
                        case SegmentType.ARC:
                            var start = s.start_angle;
                            var end = s.end_angle;
                            int large_arc;
                            int sweep;
                            if (s.reverse) {
                                sweep = 0;
                            } else {
                                sweep = 1;
                            }
                            if (end - start > Math.PI) {
                                large_arc = 1 - sweep;
                            } else {
                                large_arc = sweep;
                            }
                            yield stream.write_all_async ("A %f %f %f %d %d %f %f ".printf (s.rx, s.ry, s.angle, large_arc, sweep, s.end.x, s.end.y).data, 0, null, out written);
                            break;
                    }
                    s = s.next;
                }
                yield stream.write_all_async ("Z\" />\n".data, 0, null, out written);
            }
            yield stream.write_all_async ("</svg>\n".data, 0, null, out written);
       } catch (Error e) {
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
        
        Xml.Node* defs = new Xml.Node (null, "defs");
        svg->add_child (defs);
        
        var pattern_index = 0;
        
        for (var i = 0; i < paths.length; i++) {
            var path = paths.index (i);
            
            var fill = "";
            var stroke = "";
            
            switch (path.fill.pattern_type) {
                case NONE:
                    fill = "none";
                    break;
                case COLOR:
                    fill = "rgba(%d,%d,%d,%f)".printf ((int) path.fill.rgba.red*255, (int) path.fill.rgba.green*255, (int) path.fill.rgba.blue*255, path.fill.rgba.alpha);
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
                        stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) stop.rgba.red*255, (int) stop.rgba.green*255, (int) stop.rgba.blue*255));
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
                        stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) stop.rgba.red*255, (int) stop.rgba.green*255, (int) stop.rgba.blue*255));
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
                    stroke = "rgba(%d,%d,%d,%f)".printf ((int) path.stroke.rgba.red*255, (int) path.stroke.rgba.green*255, (int) path.stroke.rgba.blue*255, path.stroke.rgba.alpha);
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
                        stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) stop.rgba.red*255, (int) stop.rgba.green*255, (int) stop.rgba.blue*255));
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
                        stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) stop.rgba.red*255, (int) stop.rgba.green*255, (int) stop.rgba.blue*255));
                        stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                        stroke_element->add_child (stop_element);
                    }
                    
                    defs->add_child (stroke_element);
                    break;
            }
            
            Xml.Node* element = new Xml.Node (null, "path");
            
            element->new_prop ("fill", fill);
            element->new_prop ("stroke", stroke);
            element->new_prop ("d", path.to_string ());
            svg->add_child (element);
        }
        
        var res = doc->save_file (file.get_path ());
        if (res < 0) {
            // TODO: communicate error
        }
    }
}
