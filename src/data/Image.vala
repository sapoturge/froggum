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

    // Used when loading files
    private uint8[] buffer = new uint8[1024];
    private size_t index = 1024;
    private size_t end_of_buffer = 1024;

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
        // TODO: Better autosave.
        update.connect (() => { save.begin(); });
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
        this._file = file;
        var stream = file.read ();
        var tag = get_tag (stream);
        this.paths = new Array<Path> ();
        while (tag != null) {
            // Better methods certainly exist, for when I can access them.
            if (tag.has_prefix ("svg ")) {
                this.width = get_property (tag, "width").to_int ();
                this.height = get_property (tag, "height").to_int ();
            } else if (tag.has_prefix ("path ")) {
                var style = get_property (tag, "style");
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
                Gdk.RGBA fill = {fill_red / 255.0, fill_green / 255.0, fill_blue / 255.0, fill_alpha};
                Gdk.RGBA stroke = {stroke_red / 255.0, stroke_green / 255.0, stroke_blue / 255.0, stroke_alpha};
                var data = get_property (tag, "d");
                paths.append_val(new Path.from_string (data, fill, stroke, "Path"));
            }
            tag = get_tag (stream);
        }
        setup_signals ();
    }

    private string? get_tag (InputStream stream) {
        var content = new uint8[] {};
        var found_tag = false;
        // Exits internally on end of file or end of tag.
        while (true) {
            if (index == end_of_buffer) {
                if (index == 1024) {
                    index = -1;
                    stream.read_all (buffer, out end_of_buffer);
                } else {
                    return null;
                }
            } else if (found_tag) {
                if (buffer[index] == '>') {
                    return (string) content;
                } else {
                    content += buffer[index];
                }
            } else {
                if (buffer[index] == '<') {
                    found_tag = true;
                }
            }
            index += 1;
        }
    }

    private string get_property (string tag, string property) {
        var start_index = tag.index_of (" =".splice (1, 1, property));
        var real_start = tag.index_of_char ('"', start_index) + 1;
        var real_end = tag.index_of_char ('"', real_start);
        return tag.substring (real_start, real_end - real_start);
    }

    public File file {
        get {
            return _file;
        }
        set {
            _file = value;
            save.begin ();
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
                yield stream.write_all_async ("<path style=\"fill:#".data, 0, null, out written);
                yield stream.write_all_async ("%02x%02x%02x".printf ((uint) (path.fill.red * 255),
                                                         (uint) (path.fill.green * 255),
                                                         (uint) (path.fill.blue * 255)).data, 0, null, out written);
                yield stream.write_all_async (";stroke:#".data, 0, null, out written);
                yield stream.write_all_async ("%02x%02x%02x".printf ((uint) (path.stroke.red * 255),
                                                         (uint) (path.stroke.green * 255),
                                                         (uint) (path.stroke.blue * 255)).data, 0, null, out written);
                yield stream.write_all_async (";fill-opacity:%f;stroke-opacity:%f".printf (path.fill.alpha, path.stroke.alpha).data, 0, null, out written);
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
}
