public class PatternButton : Gtk.Button {
    private Pattern _pattern;
    public Pattern pattern {
        get {
            return _pattern;
        }
        set {
            _pattern = value;
            view.set_draw_func ((d, cr, w, h) => {
                pattern.apply_custom (cr, {0, 0}, {w, h}, pattern.pattern_type);
                cr.paint ();
            });
            value.update.connect (() => { view.queue_draw (); });
        }
    }

    private Gtk.DrawingArea view;

    construct {
        view = new Gtk.DrawingArea ();
        view.content_width = 32;
        view.content_height = 32;
        child = view;
        clicked.connect (() => {
            var dialog = new PatternChooserDialog ();
            bind_property ("pattern", dialog, "pattern");
            dialog.pattern = pattern;
            dialog.show ();
        });
    }
}
