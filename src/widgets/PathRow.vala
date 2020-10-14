public class PathRow : Gtk.ListBoxRow {
    private Image image;
    private int view_width;
    private int view_height;
    private double view_scale;

    private Gtk.DrawingArea view;
    private Gtk.Entry title;
    private PatternButton fill;
    private PatternButton stroke;

    public Element element { get; private set; }

    public PathRow (Image image, Element element) {
        this.image = image;
        this.element = element;
        view_scale = 32.0 / image.height;
        view.set_size_request ((int) (image.width * view_scale), (int) (image.height * view_scale));
        element.update.connect (() => {
            view.queue_draw_area (0, 0, view_width, view_height);
        });
        element.select.connect ((selected) => {
            if (selected && !is_selected ()) {
                activate ();
            }
        });
        title.text = element.title;
        element.bind_property ("title", title, "text", BindingFlags.BIDIRECTIONAL);
        fill.pattern = element.fill;
        fill.bind_property ("pattern", element, "fill");
        stroke.pattern = element.stroke;
        stroke.bind_property ("pattern", element, "stroke");
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
            cr.scale(view_scale, view_scale);
            element.draw (cr);
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
            element.visible = state;
            element.update ();
        });

        fill.tooltip_text = _("Fill color");

        stroke.tooltip_text = _("Stroke color");
    }
}
