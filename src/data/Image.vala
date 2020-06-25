public class Image : Object, ListModel {
    private File file;

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
                    selected_path = path;
                    path_selected (path);
                } else if (selected == false) {
                    selected_path = null;
                    path_selected (null);
                }
            });
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
        if (selected_path != null) {
            selected_path.draw_handles (cr);
        }
    }

    public bool button_press (double x, double y, int scale) {
        var test_surf = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
        unowned var data = test_surf.get_data ();
        var cr = new Cairo.Context (test_surf);
        foreach (Path path in paths) {
           cr.set_source_rgba (0, 0, 0, 0);
           cr.set_operator (Cairo.Operator.SOURCE);
           cr.paint ();
           path.draw_handles (cr);
           if (data[(width * (int)y + (int)x) * 4 + 3] != 0) {
               selected_path = path;
               return true;
           }
        }
        // TODO: There should be a way to deselect, but clicking off once
        // doesn't work
        //if (selected_path != null) {
        //    selected_path = null;
        //    update_func ();
        //}
        return false;
    }

    public bool motion (Gdk.EventMotion e) {
        return false;
    }

    public bool button_release (Gdk.EventButton e) {
        return false;
    }
}
