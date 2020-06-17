public class Image {
    private File file;

    public int width { get; private set; }
    public int height { get; private set; }

    public string name {
        get {
            return "Untitled";
        }
    }

    private Path[] paths { get; private set; }

    public Image (string filename, int width, int height, Path[] paths = {}) {
        if (filename == "Untitled") {
        }
        this.width = width;
        this.height = height;
        this.paths = paths;
    }

    public void create_path_rows (Gtk.ListBox list_box) {
        foreach (Path path in paths) {
            var path_row = new PathRow (this, path);
            list_box.add (path_row);
        }
    }

    public void draw (Cairo.Context cr) {
        foreach (Path path in paths) {
            path.draw (cr);
        }
    }
}
