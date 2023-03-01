public class Polygon : Element {
    public LinearSegment root_segment { get; set; }

/*
    public Point handle {
        set {
            points.set (handle_index, value);
            // Notify doesn't trigger here, so we have to update manually.
            update ();
        }
    }
*/

    public Polygon (Point[] points, Pattern fill, Pattern stroke, string? title = null, owned Transform? transform = null) {
        if (title == null) {
            title = "Polygon";
        }

        if (transform == null) {
            transform = new Transform.identity ();
        }

        Object (
            fill: fill,
            stroke: stroke,
            visible: true,
            title: title,
            transform: transform
        );

        set_points (points);
    }

/*
    public Polygon.from_segments (LinearSegment[] segments, Pattern fill, Pattern stroke, Transform? trasnform = null) {
        this.segments = new Gee.UnrolledLinkedList<LinearSegment> ();
        this.segments.add_all_array (segments);
        this.fill = fill;
        this.stroke = stroke;
        visible = true;

        if (transform == null) {
            this.transform = new Transform.identity ();
        } else {
            this.transform = transform;
        }

        setup_signals ();
    }
*/

    public Polygon.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
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
        for (int i = 1; i < points.length; i++) {
            var seg = new LinearSegment (points[i], points[(i+1)%points.length]);
            setup_segment_signals (seg);
            seg.prev = last_segment;
            last_segment.next = seg;
            last_segment = seg;
        }

        last_segment.next = root_segment;
        root_segment.prev = last_segment;
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

        segment.prev.next = new_first;
        segment.next.prev = new_last;

        command.add_value (segment.prev, "next", new_first, segment);
        command.add_value (segment.next, "prev", new_last, segment);

        if (segment == root_segment) {
            root_segment = new_first;
            command.add_value (this, "root_segment", new_first, segment);
        }

        add_command (command);
    }

    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (always_draw || visible) {
            // cr.move_to (points.get (0).x, segments.get(0).start.y);
            var first = true;
            for (var segment = root_segment; first || segment != root_segment; segment = segment.next) {
                first = false;
                cr.line_to (segment.end.x, segment.end.y);
            }

            cr.close_path ();

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

        var first = true;
        for (var segment = root_segment; first || segment != root_segment; segment = segment.next) {
            first = false;
            cr.arc (segment.start.x, segment.start.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
        }

        cr.set_source_rgb (1, 0, 0);
        cr.fill ();

        fill.draw_controls (cr, zoom);
        stroke.draw_controls (cr, zoom);

        if (transform_enabled) {
            transform.draw_controls (cr, zoom);
        }
    }

    public override void begin (string prop, Value? start_location) {
    }

    public override void finish (string prop) {
        // These don't have any properties to save now.
    }

    public override Gee.List<ContextOption> options () {
        return new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.action (_("Delete Polygon"), () => { request_delete(); }),
            new ContextOption.toggle (_("Show Transformation"), this, "transform_enabled")
        });
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index, out Xml.Node* node) {
        node = new Xml.Node (null, "polygon");

        pattern_index = add_standard_attributes (node, defs, pattern_index);

        string prefix = "";
        var first = true;
        for (var segment = root_segment; first || segment != root_segment; segment = segment.next) {
            prefix = "%s %f %f".printf (prefix, segment.start.x, segment.start.y);
            first = false;
        }

        node->new_prop ("points", prefix);
        root->add_child (node);

        return pattern_index;
    }

    public override Element copy () {
        var points = new Point[] {};
        var first = true;
        for (var segment = root_segment; first || segment != root_segment; segment = segment.next) {
            points += segment.start;
            first = false;
        }

        return new Polygon (points, fill, stroke, "Copy of " + title, transform);
    }

    public override void check_controls (double x, double y, double tolerance, out Undoable obj, out string prop) {
        if (stroke.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        if (transform_enabled && transform.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        var first = true;
        for (var segment = root_segment; first || segment != root_segment; segment = segment.next) {
            if (segment.check_controls (x, y, tolerance, out obj, out prop)) {
                return;
            }
            first = false;
        }

/*
        for (int i = 0; i < points.size; i++) {
            if ((x - points.get (i).x).abs () <= tolerance && (y - points.get (i).y).abs () <= tolerance) {
                obj = this;
                handle_index = i;
                prop = "handle";
                return;
            }
        }
*/

        obj = null;
        prop = "";
        return;
    }

    public override bool clicked (double x, double y, double tolerance, out Segment? segment) {
        segment = null;

        var first = true;
        for (var lsegment = root_segment; first || lsegment != root_segment; lsegment = lsegment.next) {
            first = false;
            if (lsegment.clicked (x, y, tolerance)) {
                segment = lsegment;
                return true;
            }
        }
/*
        // This will be replaced one LinearSegments are added
        for (int i = 0; i < points.size; i++) {
            Point start = points.get (i);
            Point end = points.get ((i+1) % points.size);
            var dot = (x - start.x) * (end.x - start.x) + (y - start.y) * (end.y - start.y);
            var len_squared = (end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y);
            var scale = dot / len_squared;
            Point aligned = { start.x + (end.x - start.x) * scale, start.y + (end.y - start.y) * scale };
            if (0 <= scale && scale <= 1 && aligned.dist ({x, y}) <= tolerance) {
                return true;
            }
       }
*/

       segment = null;
       return false;
    }
}
