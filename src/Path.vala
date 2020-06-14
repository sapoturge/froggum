public class Path {
    private Segment[] segments;
    private Color fill = null;
    private Color stroke = null;

    public Path (Segment[] segments = {},
                 Color? fill = null,
                 Color? stroke = null) {
        this.segments = segments;
        this.fill = fill;
        this.stroke = stroke;
    }

    public void draw (Cairo.Context cr) {
        foreach (Segment s in segments) {
            s.do_command (cr);
        }
        if (fill != null) {
            cr.set_source_rgba (fill.r/255.0,
                                fill.g/255.0,
                                fill.b/255.0,
                                fill.a/255.0);
            if (stroke != null) {
                cr.fill_preserve ();
            } else {
                cr.fill ();
            }
        }
        if (stroke != null) {
            cr.set_source_rgba (stroke.r/255.0,
                                stroke.g/255.0,
                                stroke.b/255.0,
                                stroke.a/255.0);
            cr.stroke ();
        }
    }
}
