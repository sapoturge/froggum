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

    public Circle (double x, double y, double r, Pattern fill, Pattern stroke, string? title = null, Transform? transform = null) {
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

        if (transform == null) {
            this.transform = new Transform.identity ();
        } else {
            this.transform = transform;
            transform_enabled = !transform.is_identity ();
        }

        setup_signals ();
    }

    class LoadingData {
        public Point center;
        public double radius;
    }

    public Circle.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns, Gee.Queue<Error> errors) {
        var actions = new Gee.HashMap<string, Element.AttributeLoaderFunc<LoadingData>> ();
        actions.set ("cx", (cxtext, ref data, errors) => {
            if (!double.try_parse (cxtext, out data.center.x)) {
                errors.offer (new Error.invalid_property ("circle", "cx", cxtext, "0"));
                data.center.x = 0;
            }
        });
        actions.set ("cy", (cytext, ref data, errors) => {
            if (!double.try_parse (cytext, out data.center.y)) {
                errors.offer (new Error.invalid_property ("circle", "cy", cytext, "0"));
                data.center.y = 0;
            }
        });
        actions.set ("r", (rtext, ref data, errors) => {
            if (!double.try_parse (rtext, out data.radius)) {
                errors.offer (new Error.invalid_property ("circle", "r", rtext, "0"));
                data.radius = 0;
            }
        });
        var data = new LoadingData ();
        load_from_xml_actions (node, patterns, errors, actions, ref data);
        x = data.center.x;
        y = data.center.y;
        r = data.radius;
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
            command.add_value (this, "center", center, _last_center);
        } else if (prop == "radius") {
            command.add_value (this, "radius", radius, _last_radius);
        }
        add_command (command);
    }

    public override void cancel (string prop) {
        if (prop == "center") {
            center = _last_center;
        } else if (prop == "radius") {
            radius = _last_radius;
        }
    }

    public override Gee.List<ContextOption> options () {
        var opts = new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.deleter (_("Delete Circle"), () => { request_delete(); }),
            new ContextOption.action (_("Convert to Ellipse"), () => { replace (new Ellipse (x, y, r, r, fill, stroke, title, transform)); }),
            new ContextOption.toggle (_("Show Transformation"), this, "transform_enabled")
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
        Xml.Node* node = new Xml.Node (null, "circle");

        pattern_index = add_standard_attributes (node, defs, pattern_index);

        node->new_prop ("cx", x.to_string ());
        node->new_prop ("cy", y.to_string ());
        node->new_prop ("r", r.to_string ());
        root->add_child (node);

        return pattern_index;
    }

    public override Element copy () {
        return new Circle (x, y, r, fill.copy (), stroke.copy (), "Copy of " + title, transform.copy ());
    }

    public override bool check_controls (double x, double y, double tolerance, out Handle? handle) {
        if (check_standard_controls (x, y, tolerance, out handle)) {
            return true;
        }

        if ((x - this.x).abs () <= tolerance && (y - this.y).abs () <= tolerance) {
            handle = new BaseHandle(this, "center", new Gee.ArrayList<ContextOption> ());
            return true;
        }

        if ((x - radius.x).abs () <= tolerance && (y - radius.y).abs () <= tolerance) {
            handle = new BaseHandle(this, "radius", new Gee.ArrayList<ContextOption> ());
            return true;
        }

        handle = null;
        return false;
    }

    public override bool clicked (double x, double y, double tolerance, out Element? element, out Segment? segment) {
        segment = null;
        if ((Math.sqrt ((x - this.x) * (x - this.x) + (y - this.y) * (y - this.y)) - r).abs () <= tolerance) {
            element = this;
            return true;
        } else {
            element = null;
            return false;
        }
    }
}
