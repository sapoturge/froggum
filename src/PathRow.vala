public class PathRow : Gtk.ListBoxRow {
    private Image image;
    private Path _path;

    public delegate void UpdateFunc ();

    public PathRow (Image image, Path path, UpdateFunc update_func) {
        this.image = image;
        this._path = path;
        create (update_func);
    }

    private void create (UpdateFunc update_func) {
        var layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        var view = new Gtk.DrawingArea ();
        var visibility = new Gtk.CheckButton ();
        var title = new Gtk.Label (_path.title);
        var fill = new Gtk.ColorButton.with_rgba (_path.fill);
        var stroke = new Gtk.ColorButton.with_rgba (_path.stroke);

        layout.pack_start (view, false, false, 0);
        layout.pack_start (visibility, false, false, 0);
        layout.pack_start (title, true, false, 0);
        layout.pack_start (fill, false, false, 0);
        layout.pack_start (stroke, false, false, 0);
        add (layout);

        view.set_size_request (image.width, image.height);
        view.valign = Gtk.Align.CENTER;
        _path.bind_property ("title", title, "label", BindingFlags.DEFAULT);
        view.draw.connect ((cr) => {
            _path.draw (cr);
            return false;
        });

        // Placeholder; will be replaced with icons eventually.
        // visibility.label = "V";
        visibility.active = true;
        visibility.toggled.connect (() => {
            _path.visible = !_path.visible;
            update_func ();
        });

        fill.color_set.connect (() => {
            _path.fill = fill.get_rgba ();
            update_func ();
        });

        stroke.color_set.connect (() => {
            _path.stroke = stroke.get_rgba ();
            update_func ();
        });
    }
}
