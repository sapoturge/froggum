public class PathRow : Gtk.ListBoxRow {
    private Image image;
    private Path _path;
    private int view_width;
    private int view_height;

    private Gtk.DrawingArea view;
    private Gtk.Label title;
    private Gtk.ColorButton fill;
    private Gtk.ColorButton stroke;

    public PathRow (Image image, Path path) {
        this.image = image;
        this._path = path;
        view.set_size_request (image.width, image.height);
        _path.update.connect (() => {
            view.queue_draw_area (0, 0, view_width, view_height);
        });
        title.label = _path.title;
        _path.bind_property ("title", title, "label", BindingFlags.DEFAULT);
        fill.rgba = _path.fill;
        stroke.rgba = _path.stroke;
    }

    construct {
        var layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        view = new Gtk.DrawingArea ();
        var visibility = new Gtk.CheckButton ();
        title = new Gtk.Label ("");
        fill = new Gtk.ColorButton ();
        stroke = new Gtk.ColorButton ();

        layout.pack_start (view, false, false, 0);
        layout.pack_start (visibility, false, false, 0);
        layout.pack_start (title, true, false, 0);
        layout.pack_start (fill, false, false, 0);
        layout.pack_start (stroke, false, false, 0);
        add (layout);

        view.valign = Gtk.Align.CENTER;
        view.draw.connect ((cr) => {
            _path.draw (cr);
            return false;
        });
        view.size_allocate.connect ((alloc) => {
            view_width = alloc.width;
            view_height = alloc.height;
        });

        visibility.active = true;
        visibility.toggled.connect (() => {
            _path.visible = !_path.visible;
            _path.update ();
        });

        fill.color_set.connect (() => {
            _path.fill = fill.get_rgba ();
            _path.update ();
        });

        stroke.color_set.connect (() => {
            _path.stroke = stroke.get_rgba ();
            _path.update ();
        });
    }
}
