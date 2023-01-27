public class Polyline : Element {
    public Gee.List<Point?> points { get; set; }

    private Gee.List<Point?> last_points;
    private int handle_index;

    public Point handle {
        set {
            points.set (handle_index, value);
            // Notify doesn't trigger here, so we have to update manually.
            update ();
        }
    }

    public Polyline (Point?[] points, Pattern fill, Pattern stroke, string? title = null) {
        this.points = new Gee.UnrolledLinkedList<Point?> ();
        this.points.add_all_array (points);
        this.fill = fill;
        this.stroke = stroke;
        visible = true;
        if (title == null) {
            this.title = "Polyline";
        } else {
            this.title = title;
        }

        this.transform = new Transform.identity ();

        setup_signals ();
    }

    public Polyline.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        base.from_xml (node, patterns);
        // The documentation says this List is good at both accessing
        // items by index and insertions/deletions from the middle, both
        // of which happen frequently here.
        points = new Gee.UnrolledLinkedList<Point?> ();
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
            this.points.add ({x, y});
        }
    }

    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (always_draw || visible) {
            cr.move_to (points.get (0).x, points.get (0).y);
            for (int i = 1; i < points.size; i++) {
                cr.line_to (points.get (i).x, points.get (i).y);
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

        for (int i = 0; i < points.size; i++) {
            cr.arc (points.get (i).x, points.get (i).y, 6 / zoom, 0, Math.PI * 2);
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
        last_points = points.read_only_view;
    }

    public override void finish (string prop) {
        var command = new Command ();
        command.add_value (this, "points", points.read_only_view, last_points);
        add_command (command);
    }

    public override Gee.List<ContextOption> options () {
        return new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.action (_("Delete Polyline"), () => { request_delete(); }),
            new ContextOption.toggle (_("Show Transformation"), this, "transform_enabled")
        });
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index, out Xml.Node* node) {
        node = new Xml.Node (null, "polyline");

        pattern_index = add_standard_attributes (node, defs, pattern_index);

        string prefix = "";
        for (int i = 0; i < points.size; i++) {
            prefix = "%s %f %f".printf (prefix, points.get (i).x, points.get (i).y);
        }

        node->new_prop ("points", prefix);
        root->add_child (node);

        return pattern_index;
    }

    public override Element copy () {
        return new Polyline (points.to_array (), fill, stroke);
    }

    public override void check_controls (double x, double y, double tolerance, out Undoable obj, out string prop) {
        if (stroke.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        if (transform_enabled && transform.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        for (int i = 0; i < points.size; i++) {
            if ((x - points.get (i).x).abs () <= tolerance && (y - points.get (i).y).abs () <= tolerance) {
                obj = this;
                handle_index = i;
                prop = "handle";
                return;
            }
        }

        obj = null;
        prop = "";
        return;
    }

    public override bool clicked (double x, double y, double tolerance, out Segment? segment) {
        segment = null;

        // This will be replaced one LinearSegments are added
        for (int i = 0; i < points.size - 1; i++) {
            Point start = points.get (i);
            Point end = points.get (i+1);
            var dot = (x - start.x) * (end.x - start.x) + (y - start.y) * (end.y - start.y);
            var len_squared = (end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y);
            var scale = dot / len_squared;
            Point aligned = { start.x + (end.x - start.x) * scale, start.y + (end.y - start.y) * scale };
            if (0 <= scale && scale <= 1 && aligned.dist ({x, y}) <= tolerance) {
                return true;
            }
       }

       return false;
    }
}
