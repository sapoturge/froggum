public class PatternButton : Gtk.Button {
    private Pattern _pattern;
    public Pattern pattern {
        get {
            return _pattern;
        }
        set {
            _pattern = value;
            _pattern.notify.connect (() => {
                viewport.queue_draw_area (0, 0, width, height);
            });
        }
    }

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
        width = rect.width;
        height = rect.height;
    }

    construct {
        viewport = new Gtk.DrawingArea ();

        viewport.draw.connect ((cr) => {
            pattern.apply (cr);
            cr.paint ();
        });

        this.add (viewport);

        var context = this.get_style_context ();
        context.add_class ("color");

        clicked.connect (() => {
            dialog = new PatternChooserDialog ();
            dialog.pattern = pattern;
            dialog.run ();
            pattern = dialog.pattern;
            dialog.hide ();
        });
    }
}
        
