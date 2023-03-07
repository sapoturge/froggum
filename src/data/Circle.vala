public class Circle : Element {
    public double x { get; set; }
    public double y { get; set; }
    public double r { get; set; }

    private Point _last_radius;
    private Point _last_center;

    private Point _radius;
    public Point radius {
        get {
            return _radius;
        }
        set {
            _radius = value;
            r = Math.sqrt ((x - _radius.x) * (x - _radius.x) + (y - _radius.y) * (y - _radius.y));
            update ();
        }
    }

    public Point center {
        get {
            return {x, y};
        }
        set {
            _radius.x += (value.x - x);
            _radius.y += (value.y - y);
            x = value.x;
            y = value.y;
            update ();
        }
    }

    public Circle (double x, double y, double r, Pattern fill, Pattern stroke, string? title = null) {
        this.x = x;
        this.y = y;
        this.r = r;
        _radius = {x + r, y};
        this.fill = fill;
        this.stroke = stroke;
        visible = true;
        if (title == null) {
            this.title = "Circle";
        } else {
            this.title = title;
        }

        this.transform = new Transform.identity ();

        setup_signals ();
    }

    public Circle.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        base.from_xml (node, patterns);
        x = double.parse (node->get_prop ("cx"));
        y = double.parse (node->get_prop ("cy"));
        r = double.parse (node->get_prop ("r"));
        _radius = { x + r, y };
    }

    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (always_draw || visible) {
            cr.arc (x, y, r, 0, Math.PI * 2);
            cr.close_path ();

            if (fill == null) {
                this.fill.apply (cr);
            } else {
                cr.set_source_rgba (fill.red,
                                    fill.green,
                                    fill.blue,
                                    fill.alpha);
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

        cr.arc (x, y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (radius.x, radius.y, 6 / zoom, 0, Math.PI * 2);
        cr.set_source_rgb (1, 0, 0);
        cr.fill ();

        fill.draw_controls (cr, zoom);
        stroke.draw_controls (cr, zoom);

        if (transform_enabled) {
            transform.draw_controls (cr, zoom);
        }
    }

    public override void begin (string prop) {
        if (prop == "center") {
            _last_center = center;
        } else if (prop == "radius") {
            _last_radius = radius;
        }
    }

    public override void finish (string prop) {
        var command = new Command ();
        if (prop == "center") {
            command.add_value (this, "prop", center, _last_center);
        } else if (prop == "radius") {
            command.add_value (this, "radius", radius, _last_radius);
        }
        add_command (command);
    }

    public override Gee.List<ContextOption> options () {
        return new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.action (_("Delete Circle"), () => { request_delete(); }),
            new ContextOption.toggle (_("Show Transformation"), this, "transform_enabled")
        });
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index) {
        var node = new Xml.Node (null, "circle");

        pattern_index = add_standard_attributes (node, defs, pattern_index);

        node.new_prop ("cx", x.to_string ());
        node.new_prop ("cy", y.to_string ());
        node.new_prop ("r", r.to_string ());
        root->add_child (node);

        return pattern_index;
    }

    public override Element copy () {
        return new Circle (x, y, r, fill, stroke);
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

        if ((x - this.x).abs () <= tolerance && (y - this.y).abs () <= tolerance) {
            obj = this;
            prop = "center";
            return;
        }
        if ((x - radius.x).abs () <= tolerance && (y - radius.y).abs () <= tolerance) {
            obj = this;
            prop = "radius";
            return;
        }
        obj = null;
        prop = "";
        return;
    }

    public override bool clicked (double x, double y, double tolerance, out Segment? segment) {
        segment = null;
        return (Math.sqrt ((x - this.x) * (x - this.x) + (y - this.y) * (y - this.y)) - r).abs () <= tolerance;
    }
}
