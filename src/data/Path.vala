public class Path : Object {
    public Segment[] segments;

    public Gdk.RGBA fill { get; set; }
    public Gdk.RGBA stroke { get; set; }

    public string title { get; set; }

    public bool visible { get; set; }

    public signal void update ();

    public signal void select (bool selected);

    public Path (Segment[] segments = {},
                 Gdk.RGBA fill = {0, 0, 0, 0},
                 Gdk.RGBA stroke = {0, 0, 0, 0},
                 string title = "Path") {
        this.segments = segments;
        this.fill = fill;
        this.stroke = stroke;
        this.title = title;
        visible = true;
        foreach (Segment s in segments) {
            s.notify.connect (() => { update (); });
        }
        select.connect (() => { update(); });
    }

    public void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (!visible && !always_draw) {
            return;
        }
        cr.set_line_width (width);
        foreach (Segment s in segments) {
            s.do_command (cr);
        }
        if (fill == null) {
            fill = this.fill;
        }
        cr.set_source_rgba (fill.red,
                            fill.green,
                            fill.blue,
                            fill.alpha);
        cr.fill_preserve ();
        if (stroke == null) {
            stroke = this.stroke;
        }
        cr.set_source_rgba (stroke.red,
                            stroke.green,
                            stroke.blue,
                            stroke.alpha);
        cr.stroke ();
    }
}
