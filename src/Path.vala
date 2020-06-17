public class Path : Object {
    private Segment[] segments;

    public Gdk.RGBA fill { get; set; }
    public Gdk.RGBA stroke { get; set; }

    public string title { get; set; }

    public bool visible { get; set; }

    public Path (Segment[] segments = {},
                 Gdk.RGBA fill = {0, 0, 0, 0},
                 Gdk.RGBA stroke = {0, 0, 0, 0},
                 string title = "Path") {
        this.segments = segments;
        this.fill = fill;
        this.stroke = stroke;
        this.title = title;
        visible = true;
    }

    public void draw (Cairo.Context cr) {
        if (!visible) {
            return;
        }
        cr.set_line_width (1);
        foreach (Segment s in segments) {
            s.do_command (cr);
        }
        cr.set_source_rgba (fill.red,
                            fill.green,
                            fill.blue,
                            fill.alpha);
        cr.fill_preserve ();
        cr.set_source_rgba (stroke.red,
                            stroke.green,
                            stroke.blue,
                            stroke.alpha);
        cr.stroke ();
    }
}
