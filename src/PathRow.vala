public class PathRow : Gtk.ListBoxRow {
    private Image image;
    private Path _path;

    public PathRow (Image image, Path path) {
        this.image = image;
        this._path = path;
        create ();
    }

    private void create () {
        var layout = new Gtk.Grid ();
        var view = new Gtk.DrawingArea ();
        var title = new Gtk.Label (_path.title);
        var fill = new Gtk.ColorButton.with_rgba (_path.fill);
        var stroke = new Gtk.ColorButton.with_rgba (_path.stroke);

        layout.attach (view, 0, 0, 1, 2);
        layout.attach (title, 1, 0, 2, 1);
        layout.attach (fill, 1, 1, 1, 1);
        layout.attach (stroke, 2, 1, 1, 1);
        add (layout);

        view.set_size_request (image.width, image.height);
        _path.bind_property ("title", title, "label", BindingFlags.DEFAULT);
        view.draw.connect ((cr) => {
            _path.draw (cr);
            return false;
        });

        // fill.label = "Fill";
        fill.color_set.connect (() => {
            _path.fill = fill.get_rgba ();
        });

        // stroke.label = "Stroke";
        stroke.color_set.connect (() => {
            _path.stroke = stroke.get_rgba ();
        });
    }
}
