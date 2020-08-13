public class PathRow : Gtk.ListBoxRow {
    private Image image;
    private int view_width;
    private int view_height;

    private Gtk.DrawingArea view;
    private Gtk.Entry title;
    private PatternButton fill;
    private PatternButton stroke;

    public new Path path { get; private set; }

    public PathRow (Image image, Path path) {
        this.image = image;
        this.path = path;
        view.set_size_request (image.width, image.height);
        path.update.connect (() => {
            view.queue_draw_area (0, 0, view_width, view_height);
        });
        path.select.connect ((selected) => {
            if (selected && !is_selected ()) {
                activate ();
            }
        });
        title.text = path.title;
        path.bind_property ("title", title, "text", BindingFlags.BIDIRECTIONAL);
        fill.pattern = path.fill;
        path.bind_property ("fill", fill, "pattern", BindingFlags.BIDIRECTIONAL);
        stroke.pattern = path.stroke;
        path.bind_property ("stroke", stroke, "pattern", BindingFlags.BIDIRECTIONAL);
    }

    construct {
        var layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        view = new Gtk.DrawingArea ();
        var visibility = new Gtk.Switch ();
        title = new Gtk.Entry ();
        fill = new PatternButton ();
        stroke = new PatternButton ();

        layout.pack_start (view, false, false, 0);
        layout.pack_start (visibility, false, false, 0);
        layout.pack_start (title, true, false, 0);
        layout.pack_start (fill, false, false, 0);
        layout.pack_start (stroke, false, false, 0);
        add (layout);

        view.valign = Gtk.Align.CENTER;
        view.draw.connect ((cr) => {
            path.draw (cr);
            return false;
        });
        view.size_allocate.connect ((alloc) => {
            view_width = alloc.width;
            view_height = alloc.height;
        });

        title.has_frame = false;

        visibility.active = true;
        visibility.tooltip_text = _("Visibility");
        visibility.state_set.connect ((state) => {
            path.visible = state;
            path.update ();
        });

        fill.tooltip_text = _("Fill color");
        /* fill.use_alpha = true;
        fill.color_set.connect (() => {
            path.fill.base_color = fill.get_rgba ();
            path.update ();
        }); */

        stroke.tooltip_text = _("Stroke color");
        /* stroke.use_alpha = true;
        stroke.color_set.connect (() => {
            path.stroke.base_color = stroke.get_rgba ();
            path.update ();
        }); */
    }
}
