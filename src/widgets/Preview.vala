public class Preview : Gtk.Box {
    private Gtk.DrawingArea preview;
    private Gtk.EditableLabel title;
    private PatternButton fill_button;
    private PatternButton stroke_button;
    private Gtk.Box layout;

    private ulong preview_update_handle = 0;

    private Element? _element;
    public Element? element {
        get {
            return _element;
        }
        set {
            if (_element != null) {
                clear_element_bindings ();
            }
            _element = value;
            if (_element != null) {
                append (layout);
                setup_element_bindings ();
            } else {
                remove (layout);
            }
        }
    }

    public Preview () {}

    construct {
        preview = new Gtk.DrawingArea () {
            tooltip_text = _("Element preview"),
            halign = CENTER,
        };
        preview.set_draw_func ((d, cr, w, h) => {
            element.draw (cr);
        });
        
        title = new Gtk.EditableLabel ("") {
            hexpand = true,
            tooltip_text = _("Element name"),
        };
        title.changed.connect (() => {
            element.begin ("title");
            element.title = title.text;
            element.finish ("title");
        });

        fill_button = new PatternButton () {
            tooltip_text = _("Fill pattern"),
        };
        
        stroke_button = new PatternButton () {
            tooltip_text = _("Stroke pattern"),
        };
        
        var fill_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3) {
            hexpand = true,
        };
        fill_box.append (new Gtk.Label (_("Fill")));
        fill_box.append (fill_button);

        var stroke_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3) {
            hexpand = true,
        };
        stroke_box.append (new Gtk.Label (_("Stroke")));
        stroke_box.append (stroke_button);

        var pattern_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        pattern_row.append (fill_box);
        pattern_row.append (stroke_box);

        layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        layout.append (preview);
        layout.append (title);
        layout.append (pattern_row);

        // Don't add layout as a child until there's an element to preview
    }

    private void clear_element_bindings () {
        element.disconnect (preview_update_handle);
    }

    private void setup_element_bindings () {
        preview.content_width = (int) element.transform.width;
        preview.content_height = (int) element.transform.height;
        preview_update_handle = element.update.connect (() => preview.queue_draw ());
        title.text = element.title;
        fill_button.pattern = element.fill;
        stroke_button.pattern = element.stroke;
    }
}