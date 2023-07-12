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
    // private PatternButton fill;
    // private PatternButton stroke;

    // public Element element { get; private set; }

    private ulong view_handle;
    private ulong visibility_handle;
    private ulong title_handle;

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;

        expander = new Gtk.TreeExpander ();
        view = new Gtk.DrawingArea ();
        visibility = new Gtk.ToggleButton ();
        title = new Gtk.EditableLabel ("Element");

        append (expander);
        append (view);
        append (visibility);
        append (title);
        // append (fill);
        // append (stroke);

        // this.image = image;
        // this.element = element;
        // view_scale = 32.0 / image.height;
        // view.set_size_request ((int) (image.width * view_scale), (int) (image.height * view_scale));
        // element.update.connect (() => {
        //     view.queue_draw_area (0, 0, view_width, view_height);
        // });
        // element.select.connect ((selected) => {
        //     if (selected && !is_selected ()) {
        //         activate ();
        //     }
        // });
        // title.text = element.title;
        // element.bind_property ("title", title, "text", BindingFlags.BIDIRECTIONAL);
        // fill.pattern = element.fill;
        // fill.bind_property ("pattern", element, "fill");
        // stroke.pattern = element.stroke;
        // stroke.bind_property ("pattern", element, "stroke");
    }

    // construct {
    //     // var layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
    //     // view = new Gtk.DrawingArea ();
    //     var visibility = new Gtk.ToggleButton ();
    //     title = new Gtk.EditableLabel ();
    //     // fill = new PatternButton ();
    //     // stroke = new PatternButton ();

    //     layout.pack_start (view, false, false, 0);
    //     layout.pack_start (visibility, false, false, 0);
    //     layout.pack_start (title, true, false, 0);
    //     layout.pack_start (fill, false, false, 0);
    //     layout.pack_start (stroke, false, false, 0);
    //     add (layout);

    //     view.valign = Gtk.Align.CENTER;
    //     view.draw.connect ((cr) => {
    //         cr.scale(view_scale, view_scale);
    //         element.draw (cr);
    //         return false;
    //     });
    //     view.size_allocate.connect ((alloc) => {
    //         view_width = alloc.width;
    //         view_height = alloc.height;
    //     });

    //     title.has_frame = false;

    //     visibility.active = true;
    //     visibility.tooltip_text = _("Visibility");
    //     visibility.state_set.connect ((state) => {
    //         element.visible = state;
    //         element.update ();
    //     });

    //     fill.tooltip_text = _("Fill color");

    //     stroke.tooltip_text = _("Stroke color");
    // }

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
    }

    public void unbind () {
        view.disconnect (view_handle);
        title.disconnect (title_handle);
        visibility.disconnect (visibility_handle);
    }
}
