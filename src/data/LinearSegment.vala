public class LinearSegment : Segment {
    private Point _start;
    private Point _end;
    public Point start {
        get {
            return _start;
        }
        set {
            _start = value;
            update ();
            if (editing && prev != null) {
                prev.end = value;
            }
        }
    }
    public Point end {
        get {
            return _end;
        }
        set {
            _end = value;
            update ();
            if (editing && next != null) {
                next.start = value;
            }
        }
    }

    public LinearSegment? prev { get; set; }
    public LinearSegment? next { get; set; }

    private bool editing = false;
    private Point last_start;
    private Point last_end;

    public signal void update ();
    public signal void request_split (LinearSegment s);

    public LinearSegment (Point start, Point end) {
        this.start = start;
        this.end = end;
    }

    public override Gee.List<ContextOption> options () {
        var opts = new Gee.ArrayList<ContextOption> ();
        opts.add (new ContextOption.action (_("Split Segment"), () => { request_split (this); }));
        return opts;
    }

    public override void begin (string prop) {
        last_start = start;
        last_end = end;
        editing = true;
    }

    public override void finish (string prop) {
        editing = false;
        var command = new Command ();
        if (prop == "start") {
            command.add_value (this, "start", start, last_start);
            if (prev != null) {
                command.add_value (prev, "end", start, last_start);
            }
        } else if (prop == "end") {
            command.add_value (this, "end", end, last_end);
            if (next != null) {
                command.add_value (next, "start", end, last_end);
            }
        } else {
            return;
        }

        add_command (command);
    }

    public bool clicked (double x, double y, double tolerance) {
        // Have Cairo check if the point would be covered by
        // stroking the path by tolerance.
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, 1, 1);
        var context = new Cairo.Context(surface);
        context.set_line_width(tolerance);
        context.move_to(start.x, start.y);
        context.line_to(end.x, end.y);
        return context.in_stroke(x, y);
    }

    public bool check_controls (double x, double y, double tolerance, out BaseHandle? handle) {
        if ((x - start.x).abs () <= tolerance &&
            (y - start.y).abs () <= tolerance) {
            handle = new BaseHandle(this, "start", new Gee.ArrayList<ContextOption> ());
            return true;
        }

        if ((x - end.x).abs () <= tolerance &&
            (y - end.y).abs () <= tolerance) {
            handle = new BaseHandle(this, "end", new Gee.ArrayList<ContextOption> ());
            return true;
        }

        handle = null;
        return false;
    }
}

