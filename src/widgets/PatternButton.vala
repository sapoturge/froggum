public class PatternButton : Gtk.CellRenderer {
    public Pattern pattern { get; set; }

    private PatternChooserDialog dialog;

    /* // THis needs to be replaced with a widget
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
        pattern.apply_custom (cr, {0, 0}, {cell_area.width, cell_area.height}, pattern.pattern_type);
        cr.fill ();
        cr.restore ();

    }
    */

    public override void get_preferred_width (Gtk.Widget widget, out int minimum_width, out int natural_width) {
        minimum_width = 24;
        natural_width = 48;
    }

    public override void get_preferred_height (Gtk.Widget widget, out int minimum_height, out int natural_height) {
        minimum_height = 24;
        natural_height = 32;
    }

    public override unowned Gtk.CellEditable? start_editing (Gdk.Event? event, Gtk.Widget widget, string path, Gdk.Rectangle background_area, Gdk.Rectangle cell_aea, Gtk.CellRendererState flags) {
        dialog = new PatternChooserDialog ();
        bind_property ("pattern", dialog, "pattern");
        dialog.pattern = pattern;
        dialog.show ();
        return null;
    }
}
