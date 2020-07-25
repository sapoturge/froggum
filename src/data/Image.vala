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

    private Path[] paths;

    private Path selected_path;
    private Path last_selected_path;

    public Image (string filename, int width, int height, Path[] paths = {}) {
        if (filename == "Untitled") {
        }
        this.width = width;
        this.height = height;
        this.paths = paths;
        this.selected_path = null;
        foreach (Path path in paths) {
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
        }
        // TODO: Better autosave.
        update.connect (() => { save.begin(); });
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
            return paths[position];
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
        foreach (Path path in paths) {
            path.draw (cr);
        }
    }

    public Path[] get_paths () {
        return paths;
    }

    public void new_path () {
        var path = new Path ({ new Segment.line (width - 1.5, 1.5),
                               new Segment.line (width - 1.5, height - 1.5),
                               new Segment.line (1.5, height - 1.5),
                               new Segment.line (1.5, 1.5)},
                             {0.33, 0.33, 0.33, 1},
                             {0.66, 0.66, 0.66, 1},
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
        paths += path;
        items_changed (paths.length - 1, 0, 1);
        paths[paths.length - 1].select (true);
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
        paths += path;
        items_changed (paths.length - 1, 0, 1);
        paths[paths.length - 1].select (true);
        update ();
    }

    public void path_up () {
        int i;
        for (i = 0; i < paths.length - 1; i++) {
            if (paths[i] == last_selected_path) {
                break;
            }
        }
        if (i == paths.length - 1) {
            return;
        }
        paths[i] = paths[i + 1];
        paths[i+1] = last_selected_path;
        items_changed (i, 2, 2);
        last_selected_path.select (true);
        last_selected_path.select (false);
    }

    public void path_down () {
        int i;
        for (i = 1; i < paths.length; i++) {
            if (paths[i] == last_selected_path) {
                break;
            }
        }
        if (i == paths.length) {
            return;
        }
        paths[i] = paths[i-1];
        paths[i-1] = last_selected_path;
        items_changed (i-1, 2, 2);
        last_selected_path.select (true);
        last_selected_path.select (false);
    }

    public void delete_path () {
        int i;
        for (i = 0; i < paths.length; i++) {
            if (paths[i] == last_selected_path) {
                break;
            }
        }
        if (selected_path != null) {
            selected_path.select (false);
        }
        for (var j = i; j < paths.length; j++) {
            paths[j-1] = paths[j];
        }
        paths[paths.length - 1] = null;
        // TODO: actually reduce the length of paths.
        items_changed (i, 1, 0);
        if (i > 0) {
            paths[i - 1].select (true);
        } else {
            paths[1].select (true);
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
            foreach (Path path in paths) {
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
                            yield stream.write_all_async ("C %f %f %f %f %f %f".printf (s.p1.x, s.p1.y, s.p2.x, s.p2.y, s.end.x, s.end.y).data, 0, null, out written);
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
                            yield stream.write_all_async ("A %f %f %f %d %d %f %f".printf (s.rx, s.ry, s.angle, large_arc, sweep, s.end.x, s.end.y).data, 0, null, out written);
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
