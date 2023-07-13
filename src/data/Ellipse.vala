public class Ellipse : Element {
    public double cx { get; set; }
    public double cy { get; set; }
    public double rx { get; set; }
    public double ry { get; set; }

    private double last_cx;
    private double last_cy;
    private double last_rx;
    private double last_ry;

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

    public Ellipse (double cx, double cy, double rx, double ry, Pattern fill, Pattern stroke, string? title = null) {
        this.cx = cx;
        this.cy = cy;
        this.rx = rx;
        this.ry = ry;
        this.fill = fill;
        this.stroke = stroke;
        visible = true;
        if (title == null) {
            this.title = "Ellipse";
        } else {
            this.title = title;
        }

        this.transform = new Transform.identity ();

        setup_signals ();
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

        cr.arc (top_left.x, top_left.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (top_right.x, top_right.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (bottom_left.x, bottom_left.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (bottom_right.x, bottom_right.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (center.x, center.y, 6 / zoom, 0, Math.PI * 2);
        cr.set_source_rgb (1, 0, 0);
        cr.fill ();

        cr.move_to (top_left.x, top_left.y);
        cr.line_to (top_right.x, top_right.y);
        cr.line_to (bottom_right.x, bottom_right.y);
        cr.line_to (bottom_left.x, bottom_left.y);
        cr.close_path ();
        cr.stroke ();

        fill.draw_controls (cr, zoom);
        stroke.draw_controls (cr, zoom);
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
            obj = this;
            prop = "top_left";
        } else if (top_close && right_close) {
            obj = this;
            prop = "top_right";
        } else if (bottom_close && left_close) {
            obj = this;
            prop = "bottom_left";
        } else if (bottom_close && right_close) {
            obj = this;
            prop = "bottom_right";
        } else if ((x - cx).abs () <= tolerance && (y - cy).abs () <= tolerance) {
            obj = this;
            prop = "center";
        } else {
            obj = null;
            prop = "";
        }
    }

    public override void begin (string prop) {
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

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index) {
        Xml.Node* node = new Xml.Node (null, "ellipse");
        
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

    public override bool clicked (double x, double y, double tolerance, out Element? element, out Segment? segment) {
        segment = null;
        var surf = new Cairo.ImageSurface (Cairo.Format.ARGB32, 1, 1);
        var cr = new Cairo.Context (surf);
        cr.save ();
        cr.translate (cx, cy);
        cr.scale (rx, ry);
        cr.arc (0, 0, 1, 0, Math.PI * 2);
        cr.restore ();
        if (cr.in_stroke (x, y)) {
            element = this;
            return true;
        } else {
            element = null;
            return false;
        }
    }
}
