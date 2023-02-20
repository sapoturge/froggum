public class Polygon : Element {
    public Gee.List<LinearSegment> segments { get; set; }

    private Gee.List<LinearSegment> last_segments;
    private int handle_index;

/*
    public Point handle {
        set {
            points.set (handle_index, value);
            // Notify doesn't trigger here, so we have to update manually.
            update ();
        }
    }
*/

    public Polygon (Point?[] points, Pattern fill, Pattern stroke, string? title = null) {
        this.segments = new Gee.UnrolledLinkedList<LinearSegment> ();
        for (int i = 0; i < points.length; i++) {
            var seg = new LinearSegment (points[i], points[(i+1)%points.length]);
            seg.notify.connect (() => { update (); });
            this.segments.add (seg);
        }

        this.fill = fill;
        this.stroke = stroke;
        visible = true;
        if (title == null) {
            this.title = "Polygon";
        } else {
            this.title = title;
        }

        this.transform = new Transform.identity ();

        setup_signals ();
        setup_segment_signals ();
    }

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
        setup_segment_signals ();
    }

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

        segments = new Gee.UnrolledLinkedList<LinearSegment> ();
        for (int i = 0; i < points.length; i++) {
            segments.add (new LinearSegment (points[i], points[(i+1) % points.length]));
        }

        setup_segment_signals ();
    }

    protected void setup_segment_signals () {
        for (int i = 0; i < segments.size; i++) {
            segments.get(i).next = segments.get((i+1)%segments.size);
            segments.get((i+1)%segments.size).prev = segments.get(i);

            segments.get(i).update.connect (() => { update (); });
            segments.get(i).add_command.connect ((c) => { add_command (c); });
        }
    }

    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (always_draw || visible) {
            // cr.move_to (points.get (0).x, segments.get(0).start.y);
            foreach (var segment in segments) {
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

        foreach (var segment in segments) {
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
        last_segments = segments.read_only_view;
    }

    public override void finish (string prop) {
        var command = new Command ();
        command.add_value (this, "segments", segments.read_only_view, last_segments);
        add_command (command);
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
        foreach (var segment in segments) {
            prefix = "%s %f %f".printf (prefix, segment.start.x, segment.start.y);
        }

        node->new_prop ("points", prefix);
        root->add_child (node);

        return pattern_index;
    }

    public override Element copy () {
        return new Polygon.from_segments (segments.to_array (), fill, stroke, transform);
    }

    public override void check_controls (double x, double y, double tolerance, out Undoable obj, out string prop) {
        if (stroke.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        if (transform_enabled && transform.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        foreach (var segment in segments) {
            if (segment.check_controls (x, y, tolerance, out obj, out prop)) {
                return;
            }
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

        foreach (var lsegment in segments) {
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
