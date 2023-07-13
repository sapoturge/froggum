public class Rectangle : Element {
    public double x { get; set; }
    public double y { get; set; }
    public double width { get; set; }
    public double height { get; set; }
    public double rx { get; set; }
    public double ry { get; set; }
    private bool _rounded;
    public bool rounded {
        get {
            return _rounded;
        }
        set {
            _rounded = value;
            if (value) {
                if (rx == 0) {
                    rx = 1.5;
                }

                if (ry == 0) {
                    ry = 1.5;
                }
            }
        }
    }

    private double last_x;
    private double last_y;
    private double last_width;
    private double last_height;
    private double last_rx;
    private double last_ry;

    public Point top_left {
        get {
            return { x, y };
        }
        set {
            var opposite = bottom_right;
            x = value.x;
            y = value.y;
            width = opposite.x - value.x;
            height = opposite.y - value.y;
        }
    }

    public Point top_right {
        get {
            return { x + width, y };
        }
        set {
            var opposite = bottom_left;
            y = value.y;
            width = value.x - opposite.x;
            height = opposite.y - value.y;
        }
    }

    public Point bottom_left {
        get {
            return { x, y + height };
        }
        set {
            var opposite = top_right;
            x = value.x;
            width = opposite.x - value.x;
            height = value.y - opposite.y;
        }
    }

    public Point bottom_right {
        get {
            return { x + width, y + height };
        }
        set {
            var opposite = top_left;
            width = value.x - opposite.x;
            height = value.y - opposite.y;
        }
    } 

    public Point center {
        get {
            return { x + width / 2, y + height / 2 };
        }
        set {
            x = value.x - width / 2;
            y = value.y - height / 2;
        }
    }

    public Point top_left_round {
        get {
            return { x + Math.copysign (double.min (rx, width.abs () / 2), width), y };
        }
        set {
            rx = double.max (0, double.min (width/2, value.x - x));
        }
    }

    public Point top_right_round {
        get {
            return { x + width - Math.copysign (double.min (rx, width.abs () / 2), width), y };
        }
        set {
            rx = double.max (0, double.min (width/2, x + width - value.x));
        }
    }

    public Point left_top_round {
        get {
            return { x, y + Math.copysign (double.min (ry, height.abs () / 2), height) };
        }
        set {
            ry = double.max (0, double.min (height/2, value.y - y));
        }
    }

    public Point left_bottom_round {
        get {
            return { x, y + height - Math.copysign (double.min (ry, height.abs () / 2), height) };
        }
        set {
            ry = double.max (0, double.min (width/2, y + height - value.y));
        }
    }

    public Point bottom_left_round {
        get {
            return { x + Math.copysign (double.min (rx, width.abs () / 2), width), y + height };
        }
        set {
            rx = double.max (0, double.min (width/2, value.x - x));
        }
    }

    public Point bottom_right_round {
        get {
            return { x + width - Math.copysign (double.min (rx, width.abs () / 2), width), y + height };
        }
        set {
            rx = double.max (0, double.min (width/2, x + width - value.x));
        }
    }

    public Point right_top_round {
        get {
            return { x + width, y + Math.copysign (double.min (ry, height.abs () / 2), height) };
        }
        set {
            ry = double.max (0, double.min (height/2, value.y - y));
        }
    }

    public Point right_bottom_round {
        get {
            return { x + width, y + height - Math.copysign (double.min (ry, height.abs () / 2), height) };
        }
        set {
            ry = double.max (0, double.min (height/2, y + height - value.y));
        }
    }

    public Rectangle (double x, double y, double width, double height, Pattern fill, Pattern stroke, string? title = null) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.fill = fill;
        this.stroke = stroke;
        visible = true;
        if (title == null) {
            this.title = "Rectangle";
        } else {
            this.title = title;
        }

        this.transform = new Transform.identity ();

        setup_signals ();

        this.rounded = false;
        this.rx = 0;
        this.ry = 0;
    }

    public Rectangle.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        base.from_xml (node, patterns);
        x = double.parse (node->get_prop ("x"));
        y = double.parse (node->get_prop ("y"));
        width = double.parse (node->get_prop ("width"));
        height = double.parse (node->get_prop ("height"));

        var rx = node->get_prop ("rx");
        var ry = node->get_prop ("ry");
        if (rx != null || ry != null) {
            if (rx == null) {
                rx = ry;
            }

            if (ry == null) {
                ry = rx;
            }

            this.rx = double.parse (rx);
            this.ry = double.parse (ry);

            rounded = this.rx > 0 && this.ry > 0;
        } else {
            rounded = false;
            this.rx = 0;
            this.ry = 0;
        }
    }

    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (always_draw || visible) {
            if (rounded && this.width != 0 && this.height != 0 && this.rx > 0 && this.ry > 0) {
                var rx = Math.copysign (double.min (this.rx, this.width.abs () / 2), this.width);
                var ry = Math.copysign (double.min (this.ry, this.height.abs () / 2), this.height);
                cr.save ();
                cr.translate (x + rx, y + ry);
                cr.scale (rx, ry);
                cr.arc (0, 0, 1, Math.PI, 3 * Math.PI / 2);
                cr.restore ();
                cr.save ();
                cr.translate (x + this.width - rx, y + ry);
                cr.scale (rx, ry);
                cr.arc (0, 0, 1, 3 * Math.PI / 2, 0);
                cr.restore ();
                cr.save ();
                cr.translate (x + this.width - rx, y + this.height - ry);
                cr.scale (rx, ry);
                cr.arc (0, 0, 1, 0, Math.PI / 2);
                cr.restore ();
                cr.save ();
                cr.translate (x + rx, y + this.height - ry);
                cr.scale (rx, ry);
                cr.arc (0, 0, 1, Math.PI / 2, Math.PI);
                cr.restore ();
                cr.close_path ();
            } else {
                cr.move_to (x, y);
                cr.line_to (x+this.width, y);
                cr.line_to (x+this.width, y+height);
                cr.line_to (x, y+height);
                cr.close_path ();
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
                cr.set_source_rgba (stroke.red, stroke.green, stroke.blue, stroke.alpha);
            }

            cr.set_line_width (width);
            cr.stroke ();
        }
    }

    public override void draw_controls (Cairo.Context cr, double zoom) {
        draw (cr, 1 / zoom, { 0, 0, 0}, {1, 0, 0, 1}, true);

        if (rounded) {
            cr.move_to (top_left_round.x, top_left_round.y);
            cr.line_to (top_left.x, top_left.y);
            cr.line_to (left_top_round.x, left_top_round.y);
            cr.move_to (top_right_round.x, top_right_round.y);
            cr.line_to (top_right.x, top_right.y);
            cr.line_to (right_top_round.x, right_top_round.y);
            cr.move_to (bottom_left_round.x, bottom_left_round.y);
            cr.line_to (bottom_left.x, bottom_left.y);
            cr.line_to (left_bottom_round.x, left_bottom_round.y);
            cr.move_to (bottom_right_round.x, bottom_right_round.y);
            cr.line_to (bottom_right.x, bottom_right.y);
            cr.line_to (right_bottom_round.x, right_bottom_round.y);

            cr.set_source_rgba (0, 0.5, 1, 0.8);
            cr.stroke ();
        }

        cr.arc (top_left.x, top_left.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (top_right.x, top_right.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (bottom_left.x, bottom_left.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (bottom_right.x, bottom_right.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (center.x, center.y, 6 / zoom, 0, Math.PI * 2);

        if (rounded) {
            cr.new_sub_path ();
            cr.arc (top_left_round.x, top_left_round.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
            cr.arc (top_right_round.x, top_right_round.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
            cr.arc (left_top_round.x, left_top_round.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
            cr.arc (left_bottom_round.x, left_bottom_round.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
            cr.arc (bottom_left_round.x, bottom_left_round.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
            cr.arc (bottom_right_round.x, bottom_right_round.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
            cr.arc (right_top_round.x, right_top_round.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
            cr.arc (right_bottom_round.x, right_bottom_round.y, 6 / zoom, 0, Math.PI * 2);
        }

        cr.set_source_rgb (1, 0, 0);
        cr.fill ();

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

        var left_close = (x - this.x).abs () <= tolerance;
        var right_close = (x - this.x - width).abs () <= tolerance;
        var top_close = (y - this.y).abs () <= tolerance;
        var bottom_close = (y - this.y - height).abs () <= tolerance;

        if (rounded) {
            var rx_left_close = (x - this.x - rx).abs () <= tolerance;
            var rx_right_close = (x - this.x - width + rx).abs () <= tolerance;
            var ry_top_close = (y - this.y - ry).abs () <= tolerance;
            var ry_bottom_close = (y - this.y - height + ry).abs () <= tolerance;
            if (top_close && rx_left_close) {
                obj = this;
                prop = "top_left_round";
                return;
            } else if (top_close && rx_right_close) {
                obj = this;
                prop = "top_right_round";
                return;
            } else if (left_close && ry_top_close) {
                obj = this;
                prop = "left_top_round";
                return;
            } else if (left_close && ry_bottom_close) {
                obj = this;
                prop = "left_bottom_round";
                return;
            } else if (bottom_close && rx_left_close) {
                obj = this;
                prop = "bottom_left_round";
                return;
            } else if (bottom_close && rx_right_close) {
                obj = this;
                prop = "bottom_right_round";
                return;
            } else if (right_close && ry_top_close) {
                obj = this;
                prop = "right_top_round";
                return;
            } else if (right_close && ry_bottom_close) {
                obj = this;
                prop = "right_bottom_round";
                return;
            }
        }

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
        } else if ((x - center.x).abs () <= tolerance && (y - center.y).abs () <= tolerance) {
            obj = this;
            prop = "center";
        } else {
            obj = null;
            prop = "";
        }
    }

    public override void begin (string prop) {
        last_x = x;
        last_y = y;
        last_width = width;
        last_height = height;
        last_rx = rx;
        last_ry = ry;
    }

    public override void finish (string prop) {
        var command = new Command ();

        switch (prop) {
        case "rounded":
            command.add_value (this, "rounded", rounded, !rounded);
            break;
        case "center":
            command.add_value (this, "x", x, last_x);
            command.add_value (this, "y", y, last_y);
            break;
        case "top_left_round":
        case "top_right_round":
        case "bottom_left_round":
        case "bottom_right_round":
            command.add_value (this, "rx", rx, last_rx);
            break;
        case "left_top_round":
        case "left_bottom_round":
        case "right_top_round":
        case "right_bottom_round":
            command.add_value (this, "ry", ry, last_ry);
            break;
        default:
            if (width < 0) {
                width = -width;
                x = x - width;
            }

            if (height < 0) {
                height = -height;
                y = y - height;
            }

            command.add_value (this, "width", width, last_width);
            command.add_value (this, "height", height, last_height);

            if (prop == "top_left" || prop == "top_right") {
                command.add_value (this, "y", y, last_y);
            }

            if (prop == "top_left" || prop == "bottom_left") {
                command.add_value (this, "x", x, last_x);
            }

            if (rx > width / 2) {
                rx = width / 2;
                command.add_value (this, "rx", rx, last_rx);
            }

            if (ry > height / 2) {
                ry = height / 2;
                command.add_value (this, "ry", ry, last_ry);
            }

            break;
        }

        add_command (command);
    }

    public override Gee.List<ContextOption> options () {
        return new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.action (_("Delete Rectangle"), () => { request_delete(); }),
            new ContextOption.toggle (_("Round Corners"), this, "rounded"),
            new ContextOption.toggle (_("Show Transformation"), this, "transform_enabled")
        });
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index) {
        Xml.Node* node = new Xml.Node (null, "rect");
        
        pattern_index = add_standard_attributes (node, defs, pattern_index);

        node->new_prop ("x", x.to_string ());
        node->new_prop ("y", y.to_string ());
        node->new_prop ("width", width.to_string ());
        node->new_prop ("height", height.to_string ());

        if (rounded && rx > 0 && ry > 0) {
            node->new_prop ("rx", rx.to_string ());
            node->new_prop ("ry", ry.to_string ());
        }

        root->add_child (node);

        return pattern_index;
    }

    public override Element copy () {
        return new Rectangle (x, y, width, height, fill, stroke);
    }

    public override bool clicked (double x, double y, double tolerance, out Element? element, out Segment? segment) {
        segment = null;
        var in_x = this.x - tolerance < x && x < this.x + width + tolerance;
        var in_y = this.y - tolerance < y && y < this.y + height + tolerance;

        if (in_x && in_y) {
            if (rounded && rx > 0 && ry > 0) {
                // Dealing with clicking on rounding is more complex
                // than I want to deal with manually.
                var surf = new Cairo.ImageSurface (Cairo.Format.ARGB32, 1, 1);
                var context = new Cairo.Context (surf);
                context.set_line_width (tolerance);
                context.save ();
                context.translate (this.x + rx, this.y + ry);
                context.scale (rx, ry);
                context.arc (0, 0, 1, Math.PI, 3 * Math.PI / 2);
                context.restore ();
                context.save ();
                context.translate (this.x + width - rx, this.y + ry);
                context.scale (rx, ry);
                context.arc (0, 0, 1, 3 * Math.PI / 2, 0);
                context.restore ();
                context.save ();
                context.translate (this.x + width - rx, this.y + height - ry);
                context.scale (rx, ry);
                context.arc (0, 0, 1, 0, Math.PI / 2);
                context.restore ();
                context.save ();
                context.translate (this.x + rx, this.y + height - ry);
                context.scale (rx, ry);
                context.arc (0, 0, 1, Math.PI / 2, Math.PI);
                context.restore ();
                context.close_path ();
                if (context.in_stroke (x, y)) {
                    element = this;
                    return true;
                } else {
                    element = null;
                    return false;
                }
            } else {
                var on_top = y < this.y + tolerance;
                var on_bottom = this.y + height - tolerance < y;
                var on_left = x < this.x + tolerance;
                var on_right = this.x + width - tolerance < x;
                if (in_x && in_y && (on_top || on_bottom || on_left || on_right)) {
                    element = this;
                    return true;
                } else {
                    element = null;
                    return false;
                }
            }
        } else {
            element = null;
            return false;
        }
    }
}
