public class Rectangle : Element {
    public double x { get; set; }
    public double y { get; set; }
    public double width { get; set; }
    public double height { get; set; }
    public double rx { get; set; }
    public double ry { get; set; }
    public bool rounded { get; set; }

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

        this.rounded = true;
        this.rx = 1.5;
        this.ry = 1.5;
    }

    public Rectangle.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        base.from_xml (node, patterns);
        x = double.parse (node->get_prop ("x"));
        y = double.parse (node->get_prop ("y"));
        width = double.parse (node->get_prop ("width"));
        height = double.parse (node->get_prop ("height"));

        this.rounded = true;
        this.rx = 1.5;
        this.ry = 1.5;
    }

    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (always_draw || visible) {
            if (rounded) {
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

        var left_close = (x - this.x).abs () <= tolerance;
        var right_close = (x - this.x - width).abs () <= tolerance;
        var top_close = (y - this.y).abs () <= tolerance;
        var bottom_close = (y - this.y - height).abs () <= tolerance;

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

    public override void begin (string prop, Value? start) {
        last_x = x;
        last_y = y;
        last_width = width;
        last_height = height;
    }

    public override void finish (string prop) {
        var command = new Command ();

        if (prop == "center") {
            command.add_value (this, "x", x, last_x);
            command.add_value (this, "y", y, last_y);
        } else {
            command.add_value (this, "width", width, last_width);
            command.add_value (this, "height", height, last_height);

            if (prop == "top_left" || prop == "top_right") {
                command.add_value (this, "y", y, last_y);
            }

            if (prop == "top_left" || prop == "bottom_left") {
                command.add_value (this, "x", x, last_x);
            }
        }

        add_command (command);
    }

    public override Gee.List<ContextOption> options () {
        return new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.action (_("Delete Rectangle"), () => { request_delete(); }),
            new ContextOption.toggle (_("Show Transformation"), this, "transform_enabled")
        });
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index, out Xml.Node* node) {
        node = new Xml.Node (null, "rect");
        
        pattern_index = add_standard_attributes (node, defs, pattern_index);

        node->new_prop ("x", x.to_string ());
        node->new_prop ("y", y.to_string ());
        node->new_prop ("width", width.to_string ());
        node->new_prop ("height", height.to_string ());

        root->add_child (node);

        return pattern_index;
    }

    public override Element copy () {
        return new Rectangle (x, y, width, height, fill, stroke);
    }

    public override bool clicked (double x, double y, double tolerance, out Segment? segment) {
        segment = null;
        var in_x = this.x - tolerance < x && x < this.x + width + tolerance;
        var in_y = this.y - tolerance < y && y < this.y + height + tolerance;
        var on_top = y < this.y + tolerance;
        var on_bottom = this.y + height - tolerance < y;
        var on_left = x < this.x + tolerance;
        var on_right = this.x + width - tolerance < x;
        return (in_x && in_y && (on_top || on_bottom || on_left || on_right));
    }
}
