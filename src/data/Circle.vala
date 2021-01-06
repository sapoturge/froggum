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
    }

    public override void begin (string prop, Value? start_location) {
        if (prop == "center") {
            _last_center = *((Point*) start_location.peek_pointer ());
        } else if (prop == "radius") {
            _last_radius = *((Point*) start_location.peek_pointer ());
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

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index, out Xml.Node* node) {
        var fill_text = "";
        var stroke_text = "";

        switch (fill.pattern_type) {
            case NONE:
                fill_text = "none";
                break;
            case COLOR:
                fill_text = "rgba(%d,%d,%d,%f)".printf ((int) (fill.rgba.red*255), (int) (fill.rgba.green*255), (int) (fill.rgba.blue*255), fill.rgba.alpha);
                break;
            case LINEAR:
                pattern_index++;
                fill_text = "url(#linearGrad%d)".printf (pattern_index);
                Xml.Node* fill_element = new Xml.Node (null, "linearGradient");
                fill_element->new_prop ("id", "linearGrad%d".printf (pattern_index));
                fill_element->new_prop ("x1", fill.start.x.to_string ());
                fill_element->new_prop ("y1", fill.start.y.to_string ());
                fill_element->new_prop ("x2", fill.end.x.to_string ());
                fill_element->new_prop ("y2", fill.end.y.to_string ());
                fill_element->new_prop ("gradientUnits", "userSpaceOnUse");
                
                for (int j = 0; j < fill.get_n_items (); j++) {
                    var stop = (Stop) fill.get_item (j);
                    Xml.Node* stop_element = new Xml.Node (null, "stop");
                    stop_element->new_prop ("offset", stop.offset.to_string ());
                    stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                    stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                    fill_element->add_child (stop_element);
                }
                
                defs->add_child (fill_element);
                break;
            case RADIAL:
                pattern_index++;
                fill_text = "url(#radialGrad%d)".printf (pattern_index);
                Xml.Node* fill_element = new Xml.Node (null, "radialGradient");
                fill_element->new_prop ("id", "radialGrad%d".printf (pattern_index));
                fill_element->new_prop ("cx", fill.start.x.to_string ());
                fill_element->new_prop ("cy", fill.start.y.to_string ());
                fill_element->new_prop ("fx", fill.start.x.to_string ());
                fill_element->new_prop ("fy", fill.start.y.to_string ());
                fill_element->new_prop ("r", Math.hypot (fill.end.x - fill.start.x, fill.end.y - fill.start.y).to_string ());
                fill_element->new_prop ("fr", "0");
                fill_element->new_prop ("gradientUnits", "userSpaceOnUse");
                
                for (int j = 0; j < fill.get_n_items (); j++) {
                    var stop = (Stop) fill.get_item (j);
                    Xml.Node* stop_element = new Xml.Node (null, "stop");
                    stop_element->new_prop ("offset", stop.offset.to_string ());
                    stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                    stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                    fill_element->add_child (stop_element);
                }
                
                defs->add_child (fill_element);
                break;
        }
        
        switch (stroke.pattern_type) {
            case NONE:
                stroke_text = "none";
                break;
            case COLOR:
                stroke_text = "rgba(%d,%d,%d,%f)".printf ((int) (stroke.rgba.red*255), (int) (stroke.rgba.green*255), (int) (stroke.rgba.blue*255), stroke.rgba.alpha);
                break;
            case LINEAR:
                pattern_index++;
                stroke_text = "url(#linearGrad%d)".printf (pattern_index);
                Xml.Node* stroke_element = new Xml.Node (null, "linearGradient");
                stroke_element->new_prop ("id", "linearGrad%d".printf (pattern_index));
                stroke_element->new_prop ("x1", stroke.start.x.to_string ());
                stroke_element->new_prop ("y1", stroke.start.y.to_string ());
                stroke_element->new_prop ("x2", stroke.end.x.to_string ());
                stroke_element->new_prop ("y2", stroke.end.y.to_string ());
                stroke_element->new_prop ("gradientUnits", "userSpaceOnUse");
                
                for (int j = 0; j < stroke.get_n_items (); j++) {
                    var stop = (Stop) stroke.get_item (j);
                    Xml.Node* stop_element = new Xml.Node (null, "stop");
                    stop_element->new_prop ("offset", stop.offset.to_string ());
                    stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                    stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                    stroke_element->add_child (stop_element);
                }
                
                defs->add_child (stroke_element);
                break;
            case RADIAL:
                pattern_index++;
                stroke_text = "url(#radialGrad%d)".printf (pattern_index);
                Xml.Node* stroke_element = new Xml.Node (null, "radialGradient");
                stroke_element->new_prop ("id", "radialGrad%d".printf (pattern_index));
                stroke_element->new_prop ("cx", stroke.start.x.to_string ());
                stroke_element->new_prop ("cy", stroke.start.y.to_string ());
                stroke_element->new_prop ("fx", stroke.start.x.to_string ());
                stroke_element->new_prop ("fy", stroke.start.y.to_string ());
                stroke_element->new_prop ("r", Math.hypot (stroke.end.x - stroke.start.x, stroke.end.y - stroke.start.y).to_string ());
                stroke_element->new_prop ("fr", "0");
                stroke_element->new_prop ("gradientUnits", "userSpaceOnUse");
                
                for (int j = 0; j < stroke.get_n_items (); j++) {
                    var stop = (Stop) stroke.get_item (j);
                    Xml.Node* stop_element = new Xml.Node (null, "stop");
                    stop_element->new_prop ("offset", stop.offset.to_string ());
                    stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                    stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                    stroke_element->add_child (stop_element);
                }
                
                defs->add_child (stroke_element);
                break;
        }

        node = new Xml.Node (null, "circle");

        node->new_prop ("id", title);
        node->new_prop ("fill", fill_text);
        node->new_prop ("stroke", stroke_text);
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
