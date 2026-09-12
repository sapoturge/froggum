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
            transform_enabled = !transform.is_identity ();
        }

        setup_signals ();
    }

    class LoadingData {
        public Point[] points;
    }

    public Polyline.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns, Gee.Queue<Error> errors) {
        var actions = new Gee.HashMap<string, Element.AttributeLoaderFunc<LoadingData>> ();
        actions.set ("points", (points_str, ref data, errors) => {
            var parser = new Parser (points_str);
            var parsed_str = new StringBuilder (); // This lets Froggum show the replacement value
            while (!parser.empty ()) {
                double x, y;
                if (!parser.get_double (out x)) {
                    errors.offer (new Error.invalid_property ("polyline", "points", points_str, parsed_str.str));
                    break;
                }
                if (!parser.get_double (out y)) {
                    // Officially, if there are an odd number of points, the last one is ignored.
                    // I'm not going to do that.
                    errors.offer (new Error.invalid_property ("polyline", "points", points_str, parsed_str.str));
                    break;
                }

                data.points += Point(x, y);
                parsed_str.append_printf ("%f, %f ", x, y);
            }
        });
        var data = new LoadingData ();
        load_from_xml_actions (node, patterns, errors, actions, ref data);
        set_points (data.points);
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

    public override void draw_controls (Cairo.Context cr, double stroke_size, double handle_size) {
        draw (cr, stroke_size, {0, 0, 0, 0}, {1, 0, 0, 1}, true);

        cr.arc (root_segment.start.x, root_segment.start.y, handle_size, 0, Math.PI * 2);
        cr.new_sub_path ();

        for (var segment = root_segment; segment != null; segment = segment.next) {
            cr.arc (segment.end.x, segment.end.y, handle_size, 0, Math.PI * 2);
            cr.new_sub_path ();
        }

        cr.set_source_rgb (1, 0, 0);
        cr.fill ();

        fill.draw_controls (cr, handle_size, stroke_size);
        stroke.draw_controls (cr, handle_size, stroke_size);
    }

    public override void begin (string prop) {
    }

    public override void finish (string prop) {
    }

    public override void cancel (string prop) {
    }

    public override Gee.List<ContextOption> options () {
        var opts = new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.deleter (_("Delete Polyline"), () => { request_delete(); }),
            new ContextOption.action (_("Close Loop"), () => {
                var points = new Point[] {root_segment.start};
                for (var segment = root_segment; segment != null; segment = segment.next) {
                    points += segment.end;
                }

                replace (new Polygon (points, fill, stroke, title, transform));
            }),
            new ContextOption.toggle (_("Show Transformation"), this, "transform-enabled")
        });
        if (transform_enabled && transform_applied) {
            opts.add (new ContextOption.action (_("Revert View"), () => {
                apply_transform (new Transform.identity(), null);
            }));
        } else if (transform_enabled) {
            opts.add (new ContextOption.action (_("Apply Transformation"), () => {
                apply_transform (transform.invert (), this);
                transform_applied = true;
            }));
        }

        return opts;
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

        return new Polyline (points, fill.copy (), stroke.copy (), "Copy of " + title, transform.copy ());
    }

    public override bool check_controls (double x, double y, double tolerance, out Handle? handle) {
        if (check_standard_controls (x, y, tolerance, out handle)) {
            return true;
        }

        for (var segment = root_segment; segment != null; segment = segment.next) {
            if (segment.check_controls (x, y, tolerance, out handle)) {
                return true;
            }
        }

        handle = null;
        return false;
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
