public class Polyline : Element {
    public LinearSegment root_segment { get; set; }

    public Polyline (Point[] points, Pattern fill, Pattern stroke, string? title = null, Transform? transform = null) {
        set_points (points);
        this.fill = fill;
        this.stroke = stroke;
        visible = true;
        if (title == null) {
            this.title = "Polyline";
        } else {
            this.title = title;
        }

        if (transform == null) {
            this.transform = new Transform.identity ();
        } else {
            this.transform = transform;
        }

        setup_signals ();
    }

    public Polyline.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        base.from_xml (node, patterns);
        var points = new Point[] {};
        var points_str = node->get_prop ("points");
        var parser = new Parser (points_str);
        while (!parser.empty ()) {
            double x, y;
            if (!parser.get_double (out x)) {
                break; // TODO: Better error handling
            }
            if (!parser.get_double (out y)) {
                break; // TODO: Better error handling
            }

            points += Point(x, y);
        }

        set_points (points);
    }

    private void set_points (Point[] points) {
        root_segment = new LinearSegment (points[0], points[1]);
        setup_segment_signals (root_segment);
        var last_segment = root_segment;
        for (int i = 1; i < points.length - 1; i++) {
            var seg = new LinearSegment (points[i], points[i+1]);
            setup_segment_signals (seg);
            seg.prev = last_segment;
            last_segment.next = seg;
            last_segment = seg;
        }

        // Since this isn't a loop, the first and last segments don't connect
        last_segment.next = null;
        root_segment.prev = null;
    }

    private void setup_segment_signals (LinearSegment segment) {
        segment.notify.connect (() => { update (); });
        segment.update.connect (() => { update (); });
        segment.add_command.connect ((c) => { add_command (c); });
        segment.request_split.connect ((s) => { split_segment (s); });
    }

    private void split_segment (LinearSegment segment) {
        var command = new Command ();
        var midpoint = Point((segment.start.x + segment.end.x) / 2, (segment.start.y + segment.end.y) / 2);
        var new_first = new LinearSegment (segment.start, midpoint);
        var new_last = new LinearSegment (midpoint, segment.end);

        setup_segment_signals (new_first);
        setup_segment_signals (new_last);

        new_first.prev = segment.prev;
        new_first.next = new_last;
        new_last.prev = new_first;
        new_last.next = segment.next;

        if (segment.prev != null) {
            segment.prev.next = new_first;
            command.add_value (segment.prev, "next", new_first, segment);
        }

        if (segment.next != null) {
            segment.next.prev = new_last;
            command.add_value (segment.next, "prev", new_last, segment);
        }

        if (segment == root_segment) {
            root_segment = new_first;
            command.add_value (this, "root_segment", new_first, segment);
        }

        add_command (command);
    }

    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (always_draw || visible) {
            var segment = root_segment;
            cr.move_to (segment.start.x, segment.start.y);
            for (; segment != null; segment = segment.next) {
                cr.line_to (segment.end.x, segment.end.y);
            }

            if (fill == null) {
                this.fill.apply (cr);
            } else {
                cr.set_source_rgba (fill.red, fill.green, fill.blue, fill.alpha);
            }

            cr.fill_preserve ();

            if (stroke == null) {
                this.stroke.apply (cr);
            } else {
                cr.set_source_rgba (stroke.red,
                                    stroke.green,
                                    stroke.blue,
                                    stroke.alpha);
            }

            cr.set_line_width (width);
            cr.stroke ();
        }
    }

    public override void draw_controls (Cairo.Context cr, double zoom) {
        draw (cr, 1 / zoom, {0, 0, 0, 0}, {1, 0, 0, 1}, true);

        cr.arc (root_segment.start.x, root_segment.start.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();

        for (var segment = root_segment; segment != null; segment = segment.next) {
            cr.arc (segment.end.x, segment.end.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
        }

        cr.set_source_rgb (1, 0, 0);
        cr.fill ();

        fill.draw_controls (cr, zoom);
        stroke.draw_controls (cr, zoom);
    }

    public override void begin (string prop) {
    }

    public override void finish (string prop) {
    }

    public override Gee.List<ContextOption> options () {
        return new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.action (_("Delete Polyline"), () => { request_delete(); }),
            new ContextOption.toggle (_("Show Transformation"), this, "transform_enabled")
        });
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index) {
        Xml.Node* node = new Xml.Node (null, "polyline");

        pattern_index = add_standard_attributes (node, defs, pattern_index);

        string prefix = "%f %f".printf (root_segment.start.x, root_segment.start.y);
        for (var segment = root_segment; segment != null; segment = segment.next) {
            prefix = "%s %f %f".printf (prefix, segment.end.x, segment.end.y);
        }

        node->new_prop ("points", prefix);
        root->add_child (node);

        return pattern_index;
    }

    public override Element copy () {
        var points = new Point[] {root_segment.start};
        for (var segment = root_segment; segment != null; segment = segment.next) {
            points += segment.end;
        }

        return new Polyline (points, fill, stroke, "Copy of " + title, transform);
    }

    public override void check_controls (double x, double y, double tolerance, out Undoable obj, out string prop) {
        if (fill.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        if (stroke.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        if (transform_enabled && transform.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        for (var segment = root_segment; segment != null; segment = segment.next) {
            if (segment.check_controls (x, y, tolerance, out obj, out prop)) {
                return;
            }
        }

        obj = null;
        prop = "";
        return;
    }

    public override bool clicked (double x, double y, double tolerance, out Element? element, out Segment? segment) {
        for (var lsegment = root_segment; lsegment != null; lsegment = lsegment.next) {
            if (lsegment.clicked (x, y, tolerance)) {
                element = this;
                segment = lsegment;
                return true;
            }
        }

        element = null;
        segment = null;
        return false;
    }
}
