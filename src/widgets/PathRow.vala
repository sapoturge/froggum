public class PathRow : Gtk.Box {
    // Some commented items will be added back eventually.

    // private Image image;
    // private int view_width;
    // private int view_height;
    // private double view_scale;

    private Gtk.TreeExpander expander;
    private Gtk.DrawingArea view;
    private Gtk.ToggleButton visibility;
    private Gtk.EditableLabel title;
    private PatternButton fill;
    private PatternButton stroke;

    private Element elem;

    private ulong view_handle;
    private ulong visibility_handle;
    private ulong title_handle;

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;

        expander = new Gtk.TreeExpander ();
        view = new Gtk.DrawingArea ();
        visibility = new Gtk.ToggleButton ();
        title = new Gtk.EditableLabel ("Element") {
            hexpand = true,
        };
        fill = new PatternButton ();
        stroke = new PatternButton ();

        visibility.tooltip_text = _("Toggle visibility");
        fill.tooltip_text = _("Fill pattern");
        stroke.tooltip_text = _("Stroke pattern");

        append (expander);
        append (view);
        append (visibility);
        append (title);
        append (fill);
        append (stroke);

        // this.image = image;
        // this.element = element;
        // view_scale = 32.0 / image.height;
        // view.set_size_request ((int) (image.width * view_scale), (int) (image.height * view_scale));
    }

    public void bind (Gtk.TreeListRow row, Element elem) {
        expander.list_row = row;

        view.content_width = (int) elem.transform.width;
        view.content_height = (int) elem.transform.height;
        view.set_draw_func ((d, cr, w, h) => {
            elem.draw (cr);
        });

        view_handle = elem.update.connect (() => { view.queue_draw (); });

        visibility.active = elem.visible;
        visibility_handle = visibility.toggled.connect (() => {
            elem.visible = !elem.visible;
        });

        title.text = elem.title;
        title_handle = title.changed.connect (() => {
            elem.begin ("title");
            elem.title = title.text;
            elem.finish ("title");
        });

        fill.pattern = elem.fill;
        stroke.pattern = elem.stroke;

        this.elem = elem;
    }

    public void unbind () {
        elem.disconnect (view_handle);
        elem = null;
        title.disconnect (title_handle);
        visibility.disconnect (visibility_handle);
    }
}
