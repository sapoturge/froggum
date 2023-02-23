public class Line : Element {
    public Point start { get; set; }
    public Point end { get; set; }

    private Point last_start;
    private Point last_end;

    public Line (double x1, double y1, double x2, double y2, Pattern stroke, string? title = null) {
        this.start = { x1, y1 };
        this.end = { x2, y2 };
        this.fill = new Pattern.none ();
        this.stroke = stroke;
        visible = true;
        if (title == null) {
            this.title = "Line";
        } else {
            this.title = title;
        }

        this.transform = new Transform.identity ();

        setup_signals ();
    }

    public Line.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        base.from_xml (node, patterns);
        var x1 = double.parse (node->get_prop ("x1"));
        var y1 = double.parse (node->get_prop ("y1"));
        var x2 = double.parse (node->get_prop ("x2"));
        var y2 = double.parse (node->get_prop ("y2"));
        start = { x1, y1 };
        end = { x2, y2 };
    }

    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (always_draw || visible) {
            cr.move_to (start.x, start.y);
            cr.line_to (end.x, end.y);

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

        cr.arc (start.x, start.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (end.x, end.y, 6 / zoom, 0, Math.PI * 2);
        cr.set_source_rgb (1, 0, 0);
        cr.fill ();

        stroke.draw_controls (cr, zoom);

        if (transform_enabled) {
            transform.draw_controls (cr, zoom);
        }
    }

    public override void begin (string prop, Value? start_location) {
        if (prop == "start") {
            last_start = start;
        } else if (prop == "end") {
            last_end = end;
        }
    }

    public override void finish (string prop) {
        var command = new Command ();
        if (prop == "start") {
            command.add_value (this, "start", start, last_start);
        } else if (prop == "end") {
            command.add_value (this, "end", end, last_end);
        }
        add_command (command);
    }

    public override Gee.List<ContextOption> options () {
        return new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.action (_("Delete Line"), () => { request_delete(); }),
            new ContextOption.action (_("Convert to Polyline"), () => {
                replace (new Polyline ({start, end}, fill, stroke, title, transform));
            }),
            new ContextOption.toggle (_("Show Transformation"), this, "transform_enabled")
        });
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index, out Xml.Node* node) {
        node = new Xml.Node (null, "line");

        pattern_index = add_standard_attributes (node, defs, pattern_index);

        node->new_prop ("x1", start.x.to_string ());
        node->new_prop ("y1", start.y.to_string ());
        node->new_prop ("x2", end.x.to_string ());
        node->new_prop ("y2", end.y.to_string ());
        root->add_child (node);

        return pattern_index;
    }

    public override Element copy () {
        return new Line (start.x, start.y, end.x, end.y, stroke);
    }

    public override void check_controls (double x, double y, double tolerance, out Undoable obj, out string prop) {
        if (stroke.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        if (transform_enabled && transform.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        if ((x - start.x).abs () <= tolerance && (y - start.y).abs () <= tolerance) {
            obj = this;
            prop = "start";
            return;
        }
        if ((x - end.x).abs () <= tolerance && (y - end.y).abs () <= tolerance) {
            obj = this;
            prop = "end";
            return;
        }
        obj = null;
        prop = "";
        return;
    }

    public override bool clicked (double x, double y, double tolerance, out Segment? segment) {
        segment = null;
        var dot = (x - start.x) * (end.x - start.x) + (y - start.y) * (end.y - start.y);
        var len_squared = (end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y);
        var scale = dot / len_squared;
        Point aligned = { start.x + (end.x - start.x) * scale, start.y + (end.y - start.y) * scale };
        return 0 <= scale && scale <= 1 && aligned.dist ({x, y}) <= tolerance;
    }
}
