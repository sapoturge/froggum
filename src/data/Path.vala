public class Path : Object {
    public Segment root_segment;

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
        this.root_segment = segments[0];
        this.fill = fill;
        this.stroke = stroke;
        this.title = title;
        visible = true;
        for (int i = 0; i < segments.length; i++) {
            segments[i].notify.connect (() => { update (); });
            segments[i].next = segments[(i + 1) % segments.length];
            segments[(i + 1) % segments.length].prev = segments[i];
            segments[i].next.start = segments[i].end;
        }
        select.connect (() => { update(); });
    }

    public Path copy () {
        Segment[] new_segments = { root_segment.copy () };
        var current_segment = root_segment.next;
        while (current_segment != root_segment) {
            new_segments += current_segment.copy ();
            current_segment = current_segment.next;
        }
        return new Path (new_segments, fill, stroke, title);
    }

    public void split_segment (Segment segment) {
        Segment first;
        Segment last;
        segment.split (out first, out last);
        first.notify.connect (() => { update (); });
        last.notify.connect (() => { update (); });
        if (segment == root_segment) {
            root_segment = first;
        }
        update ();
    }

    public void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (!visible && !always_draw) {
            return;
        }
        cr.set_line_width (width);
        cr.move_to (root_segment.start.x, root_segment.start.y);
        var segment = root_segment;
        var first = true;
        while (first || segment != root_segment) {
            first = false;
            segment.do_command (cr);
            segment = segment.next;
        }
        cr.close_path ();
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
