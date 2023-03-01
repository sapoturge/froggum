public class Ellipse : Element {
    public double cx { get; set construct; }
    public double cy { get; set construct; }
    public double rx { get; set construct; }
    public double ry { get; set construct; }

    private double last_cx;
    private double last_cy;
    private double last_rx;
    private double last_ry;

    private bool editing;

    private Handle top_left;
    private Handle top_right;
    private Handle bottom_left;
    private Handle bottom_right;
    private Handle center;

/*
    public Point top_left {
        get {
            return { cx - rx, cy - ry };
        }
        set {
            var opposite = bottom_right;
            cx = (value.x + opposite.x) / 2;
            cy = (value.y + opposite.y) / 2;
            rx = cx - value.x;
            ry = cy - value.y;
        }
    }

    public Point top_right {
        get {
            return { cx + rx, cy - ry };
        }
        set {
            var opposite = bottom_left;
            cx = (value.x + opposite.x) / 2;
            cy = (value.y + opposite.y) / 2;
            rx = value.x - cx;
            ry = cy - value.y;
        }
    }

    public Point bottom_left {
        get {
            return { cx - rx, cy + ry };
        }
        set {
            var opposite = top_right;
            cx = (value.x + opposite.x) / 2;
            cy = (value.y + opposite.y) / 2;
            rx = cx - value.x;
            ry = value.y - cy;
        }
    }

    public Point bottom_right {
        get {
            return { cx + rx, cy + ry };
        }
        set {
            var opposite = top_left;
            cx = (value.x + opposite.x) / 2;
            cy = (value.y + opposite.y) / 2;
            rx = value.x - cx;
            ry = value.y - cy;
        }
    }

    public Point center {
        get {
            return { cx, cy };
        }
        set {
            cx = value.x;
            cy = value.y;
        }
    }
*/

    construct {
        editing = false;

        center = new Handle (cx, cy);
        top_left = new Handle (cx - rx, cy - ry);
        top_right = new Handle (cx + rx, cy - ry);
        bottom_left = new Handle (cx - rx, cy + ry);
        bottom_right = new Handle (cx + rx, cy + ry);

        center.notify.connect (() => {
            if (!editing) {
                editing = true;
                var offset_x = center.point.x - cx;
                var offset_y = center.point.y - cy;
                cx = center.point.x;
                cy = center.point.y;
                top_left.point = Point(top_left.point.x + offset_x, top_left.point.y + offset_y);
                top_right.point = Point(top_right.point.x + offset_x, top_right.point.y + offset_y);
                bottom_left.point = Point(bottom_left.point.x + offset_x, bottom_left.point.y + offset_y);
                bottom_right.point = Point(bottom_right.point.x + offset_x, bottom_right.point.y + offset_y);
                update ();
                editing = false;
            }
        });

        top_left.notify.connect (() => {
            if (!editing) {
                editing = true;
                cx = (bottom_right.point.x + top_left.point.x) / 2;
                cy = (bottom_right.point.y + top_left.point.y) / 2;
                rx = (bottom_right.point.x - top_left.point.x) / 2;
                ry = (bottom_right.point.y - top_left.point.y) / 2;

                top_right.point = Point(top_right.point.x, top_left.point.y);
                bottom_left.point = Point(top_left.point.x, bottom_left.point.y);
                center.point = Point(cx, cy);
                update ();
                editing = false;
            }
        });

        top_right.notify.connect (() => {
            if (!editing) {
                editing = true;
                cx = (bottom_left.point.x + top_right.point.x) / 2;
                cy = (bottom_left.point.y + top_right.point.y) / 2;
                rx = -(bottom_left.point.x - top_right.point.x) / 2;
                ry = (bottom_left.point.y - top_right.point.y) / 2;

                top_left.point = Point(top_left.point.x, top_right.point.y);
                bottom_right.point = Point(top_right.point.x, bottom_right.point.y);
                center.point = Point(cx, cy);
                update ();
                editing = false;
            }
        });

        bottom_left.notify.connect (() => {
            if (!editing) {
                editing = true;
                cx = (top_right.point.x + bottom_left.point.x) / 2;
                cy = (top_right.point.y + bottom_left.point.y) / 2;
                rx = (top_right.point.x - bottom_left.point.x) / 2;
                ry = -(top_right.point.y - bottom_left.point.y) / 2;

                bottom_right.point = Point(bottom_right.point.x, bottom_left.point.y);
                top_left.point = Point(bottom_left.point.x, top_left.point.y);
                center.point = Point(cx, cy);
                update ();
                editing = false;
            }
        });

        bottom_right.notify.connect (() => {
            if (!editing) {
                editing = true;
                cx = (top_left.point.x + bottom_right.point.x) / 2;
                cy = (top_left.point.y + bottom_right.point.y) / 2;
                rx = -(top_left.point.x - bottom_right.point.x) / 2;
                ry = -(top_left.point.y - bottom_right.point.y) / 2;

                bottom_left.point = Point(bottom_left.point.x, bottom_right.point.y);
                top_right.point = Point(bottom_right.point.x, top_right.point.y);
                center.point = Point(cx, cy);
                update ();
                editing = false;
            }
        });
    }

    public Ellipse (double cx, double cy, double rx, double ry, Pattern fill, Pattern stroke, string? title = null) {
        if (title == null) {
            title = "Ellipse";
        }

        Object (
            cx: cx,
            cy: cy,
            rx: rx,
            ry: ry,
            fill: fill,
            stroke: stroke,
            visible: true,
            title: title,
            transform: new Transform.identity ()
        );
    }

    public Ellipse.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        base.from_xml (node, patterns);
        cx = double.parse (node->get_prop ("cx"));
        cy = double.parse (node->get_prop ("cy"));
        rx = double.parse (node->get_prop ("rx"));
        ry = double.parse (node->get_prop ("ry"));
    }

    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (always_draw || visible) {
            cr.save ();
            cr.translate (cx, cy);
            cr.scale (rx, ry);
            cr.arc (0, 0, 1, 0, Math.PI * 2);
            cr.close_path ();
            cr.restore ();
    
            if (fill == null) {
                this.fill.apply (cr);
            } else {
                cr.set_source_rgba (fill.red, fill.green, fill.blue, fill.alpha);
            }

            cr.fill_preserve ();

            if (stroke == null) {
                this.stroke.apply (cr);
            } else {
                cr.set_source_rgba (stroke.red, stroke.green, stroke.blue, stroke.alpha);
            }

            cr.set_line_width (width);
            cr.stroke ();
        }
    }

    public override void draw_controls (Cairo.Context cr, double zoom) {
        draw (cr, 1 / zoom, { 0, 0, 0}, {1, 0, 0, 1}, true);

        cr.arc (top_left.point.x, top_left.point.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (top_right.point.x, top_right.point.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (bottom_left.point.x, bottom_left.point.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (bottom_right.point.x, bottom_right.point.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (center.point.x, center.point.y, 6 / zoom, 0, Math.PI * 2);
        cr.set_source_rgb (1, 0, 0);
        cr.fill ();

        cr.move_to (top_left.point.x, top_left.point.y);
        cr.line_to (top_right.point.x, top_right.point.y);
        cr.line_to (bottom_right.point.x, bottom_right.point.y);
        cr.line_to (bottom_left.point.x, bottom_left.point.y);
        cr.close_path ();
        cr.stroke ();

        fill.draw_controls (cr, zoom);
        stroke.draw_controls (cr, zoom);

        if (transform_enabled) {
            transform.draw_controls (cr, zoom);
        }
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

        var left_close = (x - cx + rx).abs () <= tolerance;
        var right_close = (x - cx - rx).abs () <= tolerance;
        var top_close = (y - cy + ry).abs () <= tolerance;
        var bottom_close = (y - cy - ry).abs () <= tolerance;

        if (top_close && left_close) {
            obj = top_left;
            prop = "point";
        } else if (top_close && right_close) {
            obj = top_right;
            prop = "point";
        } else if (bottom_close && left_close) {
            obj = bottom_left;
            prop = "point";
        } else if (bottom_close && right_close) {
            obj = bottom_right;
            prop = "point";
        } else if ((x - cx).abs () <= tolerance && (y - cy).abs () <= tolerance) {
            obj = center;
            prop = "point";
        } else {
            obj = null;
            prop = "";
        }
    }

    public override void begin (string prop, Value? start) {
        last_cx = cx;
        last_cy = cy;
        last_rx = rx;
        last_ry = ry;
    }

    public override void finish (string prop) {
        var command = new Command ();
        command.add_value (this, "cx", cx, last_cx);
        command.add_value (this, "cy", cy, last_cy);
        command.add_value (this, "rx", rx, last_rx);
        command.add_value (this, "ry", ry, last_ry);
        add_command (command);
    }

    public override Gee.List<ContextOption> options () {
        return new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.action (_("Delete Ellipse"), () => { request_delete(); }),
            new ContextOption.toggle (_("Show Transformation"), this, "transform_enabled")
        });
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index, out Xml.Node* node) {
        node = new Xml.Node (null, "ellipse");
        
        pattern_index = add_standard_attributes (node, defs, pattern_index);

        node->new_prop ("cx", cx.to_string ());
        node->new_prop ("cy", cy.to_string ());
        node->new_prop ("rx", rx.to_string ());
        node->new_prop ("ry", ry.to_string ());

        root->add_child (node);

        return pattern_index;
    }

    public override Element copy () {
        return new Ellipse (cx, cy, rx, ry, fill, stroke);
    }

    public override bool clicked (double x, double y, double tolerance, out Segment? segment) {
        segment = null;
        var surf = new Cairo.ImageSurface (Cairo.Format.ARGB32, 1, 1);
        var cr = new Cairo.Context (surf);
        cr.save ();
        cr.translate (cx, cy);
        cr.scale (rx, ry);
        cr.arc (0, 0, 1, 0, Math.PI * 2);
        cr.restore ();
        return cr.in_stroke (x, y);
    }
}
