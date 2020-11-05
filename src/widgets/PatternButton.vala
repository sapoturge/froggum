public class PatternButton : Gtk.CellRenderer {
    private Pattern _pattern;
    public Pattern pattern {
        get {
            return _pattern;
        }
        set {
            _pattern = value;
/*
            _pattern.notify.connect (() => {
                viewport.queue_draw_area (0, 0, width, height);
            });
*/
        }
    }
/*
    public string title { get; set; }

    private Gtk.DrawingArea viewport;
    private PatternChooserDialog dialog;
    private int width;
    private int height;

    public PatternButton () {
        var layout = create_pango_layout ("Black");
        Pango.Rectangle rect;
        layout.get_pixel_extents (null, out rect);
        viewport.set_size_request (rect.width, rect.height);
    }

    construct {
        viewport = new Gtk.DrawingArea ();

        viewport.size_allocate.connect ((alloc) => {
            width = alloc.width;
            height = alloc.height;
        });

        viewport.draw.connect ((cr) => {
            pattern.apply_custom (cr, {0, 0}, {width, height});
            cr.paint ();
        });

        // this.add (viewport);

        // var context = this.get_style_context ();
        // context.add_class ("color");

        clicked.connect (() => {
            dialog = new PatternChooserDialog ();
            dialog.pattern = pattern;
            dialog.run ();
            pattern = dialog.pattern;
            dialog.hide ();
        });
    }
*/
    public override void render (Cairo.Context cr, Gtk.Widget widget, Gdk.Rectangle background_area, Gdk.Rectangle cell_area, Gtk.CellRendererState flags) {
        var style = widget.get_style_context ();
        style.add_class ("button");
        style.set_junction_sides (Gtk.JunctionSides.NONE);
        var state_flags = style.get_state ();
        var border = style.get_border (state_flags);
        var margin = style.get_margin (state_flags);
        var padding = style.get_padding (state_flags);
        style.render_background (cr, background_area.x, background_area.y, background_area.width, background_area.height);
        style.render_frame (cr, cell_area.x + margin.left, cell_area.y + margin.top, cell_area.width - margin.left - margin.right, cell_area.height - margin.top - margin.bottom);

        cr.save ();
        cr.translate (cell_area.x + border.left + margin.left + padding.left, cell_area.y + border.top + margin.top + padding.top);
        cr.rectangle (0, 0, cell_area.width - border.left - border.right - margin.left - margin.right - padding.left - padding.right, cell_area.height - border.top - border.bottom - margin.top - margin.bottom - padding.top - padding.bottom);
        pattern.apply_custom (cr, {0, 0}, {cell_area.width, cell_area.height});
        cr.fill ();
        cr.restore ();

    }

    public override void get_preferred_width (Gtk.Widget widget, out int minimum_width, out int natural_width) {
        minimum_width = 24;
        natural_width = 48;
    }

    public override void get_preferred_height (Gtk.Widget widget, out int minimum_height, out int natural_height) {
        minimum_height = 24;
        natural_height = 32;
    }
}
        
