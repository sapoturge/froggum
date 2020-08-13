public class PatternButton : Gtk.Button {
    public Pattern pattern { get; set; }

    public string title { get; set; }

    private Gtk.DrawingArea viewport;

    public PatternButton () {
        var layout = create_pango_layout ("Black");
        Pango.Rectangle rect;
        layout.get_pixel_extents (null, out rect);
        viewport.set_size_request (rect.width, rect.height);
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
    }
}
        
