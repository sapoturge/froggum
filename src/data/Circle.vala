public class Circle : Element {
    public double x { get; set construct; }
    public double y { get; set construct; }
    public double r { get; set construct; }

/*
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
*/

    private Handle center;
    private Handle radius;

    construct {
        if (title == null) {
            title = "Circle";
        }

        center = new Handle (x, y);
        center.notify.connect (() => {
            var new_x = center.point.x - x + radius.point.x;
            var new_y = center.point.y - y + radius.point.y;
            x = center.point.x;
            y = center.point.y;
            radius.point = Point(new_x, new_y);
            update ();
        });
        center.add_command.connect ((c) => { add_command (c); });

        radius = new Handle (x + r, y);
        radius.notify.connect (() => {
            r = Math.sqrt ((x - radius.point.x) * (x - radius.point.x) + (y - radius.point.y) * (y - radius.point.y));
            update ();
        });
        radius.add_command.connect ((c) => { add_command (c); });
    }

    public Circle (double x, double y, double r, Pattern fill, Pattern stroke, string? title = null) {
        Object (
            x: x,
            y: y,
            r: r,
            fill: fill,
            stroke: stroke,
            visible: true,
            title: title,
            transform: new Transform.identity ()
        );
    }

    public Circle.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        base.from_xml (node, patterns);
        x = double.parse (node->get_prop ("cx"));
        y = double.parse (node->get_prop ("cy"));
        r = double.parse (node->get_prop ("r"));
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
        cr.arc (radius.point.x, radius.point.y, 6 / zoom, 0, Math.PI * 2);
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
    }

    public override Gee.List<ContextOption> options () {
        return new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.action (_("Delete Circle"), () => { request_delete(); }),
            new ContextOption.toggle (_("Show Transformation"), this, "transform_enabled")
        });
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index, out Xml.Node* node) {
        node = new Xml.Node (null, "circle");

        pattern_index = add_standard_attributes (node, defs, pattern_index);

        node->new_prop ("cx", x.to_string ());
        node->new_prop ("cy", y.to_string ());
        node->new_prop ("r", r.to_string ());
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
            obj = center;
            prop = "point";
            return;
        }

        if ((x - radius.point.x).abs () <= tolerance && (y - radius.point.y).abs () <= tolerance) {
            obj = radius;
            prop = "point";
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
