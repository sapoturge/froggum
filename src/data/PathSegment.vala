public enum SegmentType {
    NONE,
    LINE,
    CURVE,
    ARC
}

public class PathSegment : Segment {
    private SegmentType _segment_type = NONE;
    public SegmentType segment_type {
        get {
            return _segment_type;
        }
        set {
            if (_segment_type == NONE || _segment_type == value) {
                _segment_type = value;
                return;
            }
            var command = new Command ();
            command.add_value (this, "segment_type", _segment_type, value);
            if (_segment_type == CURVE) {
                command.add_value (this, "p1", p1, p1);
                command.add_value (this, "p2", p2, p2);
            } else if (_segment_type == ARC) {
                command.add_value (this, "center", center, center);
                command.add_value (this, "angle", angle, angle);
                command.add_value (this, "rx", rx, rx);
                command.add_value (this, "ry", ry, ry);
                command.add_value (this, "start", start, end);
                command.add_value (this, "end", end, end);
            }
            _segment_type = value;
            if (_segment_type == CURVE) {
                var dx = end.x - start.x;
                var dy = end.y - start.y;
                p1 = {start.x + dx / 4, start.y + dy / 4};
                p2 = {end.x - dx / 4, end.y - dy / 4};
                command.add_value (this, "p1", p1, p1);
                command.add_value (this, "p2", p2, p2);
            } else if (_segment_type == ARC) {
                var dx = end.x - start.x;
                var dy = end.y - start.y;
                center = {start.x + dx / 2, start.y + dy / 2};
                angle = Math.PI + Math.atan2 (dy, dx);
                start_angle = 0;
                end_angle = Math.PI;
                rx = Math.hypot (dy, dx) / 2;
                ry = rx / 2;
                command.add_value (this, "center", center, center);
                command.add_value (this, "angle", angle, angle);
                command.add_value (this, "rx", rx, rx);
                command.add_value (this, "ry", ry, ry);
                command.add_value (this, "start", start, end);
                command.add_value (this, "end", end, end);
            }
            add_command (command);
        }
    }

    public PathSegment prev { get; set; }
    private PathSegment _next;
    private Binding next_binding;
    public PathSegment next {
        get {
            return _next;
        }
        set {
            if (next_binding != null) {
                next_binding.unbind ();
            }
            
            _next = value;
            _next.prev = this;
            next_binding = bind_property ("end", _next, "start", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }
    }

    // End points, used for all segments
    private Point _start;
    public Point start {
        get {
            return _start;
        }
        set {
            if (segment_type == ARC) {
                var new_value = closest (value, out start_angle);
                double maximum;
                double minimum;
                if (reverse) {
                    minimum = end_angle;
                    maximum = end_angle + Math.PI * 2;
                } else {
                    maximum = end_angle;
                    minimum = end_angle - Math.PI * 2;
                }
                while (start_angle < minimum) {
                    start_angle += Math.PI * 2;
                }
                while (start_angle > maximum) {
                    start_angle -= Math.PI * 2;
                }
                if ((new_value.x - value.x).abs () + (new_value.y - value.y).abs () >= 1e-5) {
                    prev.end = new_value;
                }
                value = new_value;
            }
            if (value != _start) {
                _start = value;
            }
        }
    }

    private Point _end;
    public Point end {
        get {
            return _end;
        }
        set {
            if (segment_type == ARC) {
                value = closest (value, out end_angle);
                double maximum;
                double minimum;
                if (reverse) {
                    maximum = start_angle;
                    minimum = start_angle - Math.PI * 2;
                } else {
                    minimum = start_angle;
                    maximum = start_angle + Math.PI * 2;
                }
                while (end_angle < minimum) {
                    end_angle += Math.PI * 2;
                }
                while (end_angle > maximum) {
                    end_angle -= Math.PI * 2;
                }
            }
            if (value != _end) {
                _end = value;
            }
        }
    }

    // Control points, used for CURVE segments
    public Point p1 { get; set; }
    public Point p2 { get; set; }

    // SVG-based ARC control values
    private Point _center;
    public Point center {
        get {
            return _center;
        }
        set {
            _center = value;
            start = point_from_angle (start_angle);
            end = point_from_angle (end_angle);
        }
    }
    public double rx { get; set; default = 16; }
    public double ry { get; set; default = 16; }
    public double angle { get; set; }
    
    private bool _reverse;
    public bool reverse {
        get {
            return _reverse;
        }
        set {
            if (_reverse != value) {
                var command = new Command ();
                command.add_value (this, "reverse", value, _reverse);
                add_command (command);
                _reverse = value;
            }
        }
    }
    // Easier to use and update than just points
    public double start_angle;
    public double end_angle;

    // Control points for ARC segments
    public Point topleft {
        get {
            return {center.x - Math.cos (angle) * rx + Math.sin (angle) * ry,
                    center.y - Math.cos (angle) * ry - Math.sin (angle) * rx};
        }
        set {
            center = {(value.x + bottomright.x) / 2, (value.y + bottomright.y) / 2};
            var a = Math.atan2 (value.y - center.y, value.x - center.x);
            var d = Math.sqrt (Math.pow (value.x - center.x, 2) + Math.pow (value.y - center.y, 2));
            rx = d * Math.cos (Math.PI + a - angle);
            ry = d * Math.sin (Math.PI + a - angle);
            start = point_from_angle (start_angle);
            end = point_from_angle (end_angle);
        }
    }

    public Point topright {
        get {
            return {center.x + Math.cos (angle) * rx + Math.sin (angle) * ry,
                    center.y - Math.cos (angle) * ry + Math.sin (angle) * rx};
        }
        set {
            center = {(value.x + bottomleft.x) / 2, (value.y + bottomleft.y) / 2};
            var a = Math.atan2 (value.y - center.y, value.x - center.x);
            var d = Math.sqrt (Math.pow (value.x - center.x, 2) + Math.pow (value.y - center.y, 2));
            rx = d * Math.cos (angle - a);
            ry = d * Math.sin (angle - a);
            start = point_from_angle(start_angle);
            end = point_from_angle(end_angle);
        }
    }

    public Point bottomleft {
        get {
            return {center.x - Math.cos (angle) * rx - Math.sin (angle) * ry,
                    center.y + Math.cos (angle) * ry - Math.sin (angle) * rx};
        }
        set {
            center = {(value.x + topright.x) / 2, (value.y + topright.y) / 2};
            var a = Math.atan2 (value.y - center.y, value.x - center.x);
            var d = Math.sqrt (Math.pow (value.x - center.x, 2) + Math.pow (value.y - center.y, 2));
            rx = d * Math.cos (Math.PI + angle - a);
            ry = d * Math.sin (Math.PI + angle - a);
            start = point_from_angle(start_angle);
            end = point_from_angle(end_angle);
        }
    }
    
    public Point bottomright {
        get {
            return {center.x + Math.cos (angle) * rx - Math.sin (angle) * ry,
                    center.y + Math.cos (angle) * ry + Math.sin (angle) * rx};
        }
        set {
            center = {(value.x + topleft.x) / 2, (value.y + topleft.y) / 2};
            var a = Math.atan2 (value.y - center.y, value.x - center.x);
            var d = Math.hypot (value.x - center.x, value.y - center.y);
            rx = d * Math.cos (a - angle);
            ry = d * Math.sin (a - angle);
            start = point_from_angle(start_angle);
            end = point_from_angle(end_angle);
        }
    }

    public Point controller {
        get {
            return {center.x + Math.cos (angle) * (rx + 5),
                    center.y + Math.sin (angle) * (rx + 5)};
        }
        set {
            angle = Math.atan2 (value.y - center.y, value.x - center.x);
            start = point_from_angle(start_angle);
            end = point_from_angle(end_angle);
        }
    }
    
    // Backups for undo history
    private Point previous_start;
    private Point previous_end;
    private Point previous_p1;
    private Point previous_p2;
    private Point previous_center;
    private double previous_rx;
    private double previous_ry;
    private double previous_angle;

    public signal void request_split (PathSegment s);
            
    // Constructors
    public PathSegment.line (double x, double y) {
        segment_type = LINE;
        this.end = {x, y};
    }

    public PathSegment.curve (double x1, double y1, double x2, double y2, double x, double y) {
        segment_type = CURVE;
        this.end = {x, y};
        this.p1 = {x1, y1};
        this.p2 = {x2, y2};
    }

    public PathSegment.arc (double x, double y, double xc, double yc, double rx, double ry, double angle, bool reverse) {
        segment_type = ARC;
        this.center = {xc, yc};
        this.rx = rx;
        this.ry = ry;
        this.angle = angle;
        this.reverse = reverse;
        this.end = {x, y};
    }

    private PathSegment.none () {}
    
    public override void begin (string property) {
        switch (property) {
            case "start":
                previous_start = start;
                break;
            case "end":
                previous_end = end;
                break;
            case "p1":
                previous_p1 = p1;
                break;
            case "p2":
                previous_p2 = p2;
                break;
            case "center":
                previous_start = start;
                previous_end = end;
                previous_center = center;
                break;
            case "topleft":
            case "topright":
            case "bottomleft":
            case "bottomright":
                previous_center = center;
                previous_end = end;
                previous_start = start;
                previous_rx = rx;
                previous_ry = ry;
                break;
            case "controller":
                previous_start = start;
                previous_end = end;
                previous_angle = angle;
                break;
        }
    }
    
    public override void finish (string property) {
        var command = new Command ();
        switch (property) {
            case "start":
                command.add_value (this, "start", start, previous_start);
                break;
            case "end":
                command.add_value (this, "end", end, previous_end);
                break;
            case "p1":
                command.add_value (this, "p1", p1, previous_p1);
                break;
            case "p2":
                command.add_value (this, "p2", p2, previous_p2);
                break;
            case "center":
                command.add_value (this, "center", center, previous_center);
                command.add_value (this, "start", start, previous_start);
                command.add_value (this, "end", end, previous_end);
                break;
            case "topleft":
            case "topright":
            case "bottomleft":
            case "bottomright":
                command.add_value (this, "center", center, previous_center);
                command.add_value (this, "rx", rx, previous_rx);
                command.add_value (this, "ry", ry, previous_ry);
                command.add_value (this, "start", start, previous_start);
                command.add_value (this, "end", end, previous_end);
                break;
            case "controller":
                command.add_value (this, "angle", angle, previous_angle);
                command.add_value (this, "start", start, previous_start);
                command.add_value (this, "end", end, previous_end);
                break;
        }
        add_command (command);
    }

    public string command_text () {
        switch (segment_type) {
            case LINE:
                return "L %f %f".printf (end.x, end.y);
            case CURVE:
                return "C %f %f %f %f %f %f".printf (p1.x, p1.y, p2.x, p2.y, end.x, end.y);
            case ARC:
                var start = start_angle;
                var end = end_angle;
                int large_arc;
                int sweep;
                if (reverse) {
                    sweep = 0;
                } else {
                    sweep = 1;
                }
                if (end < start) {
                    end += 2 * Math.PI;
                }
                if (end - start > Math.PI) {
                    large_arc = sweep;
                } else {
                    large_arc = 1 - sweep;
                }
                return "A %f %f %f %d %d %f %f".printf (rx, ry, 180 * angle / Math.PI, large_arc, sweep, this.end.x, this.end.y);
            default:
                return "";
        }
    }

    public PathSegment copy () {
        switch (segment_type) {
            case LINE:
                return new PathSegment.line (end.x, end.y);
            case CURVE:
                return new PathSegment.curve (p1.x, p1.y, p2.x, p2.y, end.x, end.y);
            case ARC:
                return new PathSegment.arc (end.x, end.y, center.x, center.y, rx, ry, angle, reverse);
            default:
                log (null, LogLevelFlags.LEVEL_ERROR, "Tried to copy an unitialized segment.");
                return this;
        }
    }


    public void split (out PathSegment first, out PathSegment last) {
        switch (segment_type) {
            case LINE:
                Point center = {(start.x + end.x) / 2, (start.y + end.y) / 2};
                first = new PathSegment.line (center.x, center.y);
                last = new PathSegment.line (end.x, end.y);
                break;
            case CURVE:
                Point q1 = {(start.x + p1.x) / 2, (start.y + p1.y) / 2};
                Point q2 = {(p1.x + p2.x) / 2, (p1.y + p2.y) / 2};
                Point q3 = {(p2.x + end.x) / 2, (p2.y + end.y) / 2};
                Point r1 = {(q1.x + q2.x) / 2, (q1.y + q2.y) / 2};
                Point r2 = {(q2.x + q3.x) / 2, (q2.y + q3.y) / 2};
                Point s = {(r1.x + r2.x) / 2, (r1.y + r2.y) / 2};
                first = new PathSegment.curve (q1.x, q1.y, r1.x, r1.y, s.x, s.y);
                last = new PathSegment.curve (r2.x, r2.y, q3.x, q3.y, end.x, end.y);
                break;
            case ARC:
                // ARC segments don't work very well together.
                first = this;
                last = new PathSegment.line (end.x, end.y);
                break;
            default:
                log (null, LogLevelFlags.LEVEL_ERROR, "Tried to split an unitialized segment.");
                first = null;
                last = null;
                return;
        }
        prev.next = first;
        last.prev = first;
        last.next = next;
        next.prev = last;
        last.start = first.end;
        // Since first is sometimes this, updating its value needs to be last
        first.start = prev.end;
        first.prev = prev;
        first.next = last;
    }

    public void do_command (Cairo.Context cr) {
        switch (segment_type) {
            case LINE:
                cr.line_to (end.x, end.y);
                break;
            case CURVE:
                cr.curve_to (p1.x, p1.y, p2.x, p2.y, end.x, end.y);
                break;
            case ARC:
                cr.save ();
                cr.translate (center.x, center.y);
                cr.rotate (angle);
                cr.scale (rx, ry);
                if (reverse) {
                    cr.arc_negative (0, 0, 1, start_angle, end_angle);
                } else {
                    cr.arc (0, 0, 1, start_angle, end_angle);
                }
                cr.restore ();
                break;
            default:
                break;
        }
    }

    private Point closest (Point original, out double p_angle) {
        // Logic copied from https://stackoverflow.com/questions/22959698/distance-from-given-point-to-given-ellipse
        var dx = original.x - center.x;
        var dy = original.y - center.y;
        var an = Math.atan2 (dy, dx);
        var d = Math.hypot (dx, dy);
        var px = (Math.cos (an - angle) * d).abs ();
        var py = (Math.sin (an - angle) * d).abs ();

        var t = Math.PI / 4;

        var a = rx;
        var b = ry;

        for (int i = 0; i < 3; i++) {
            var x = a * Math.cos (t);
            var y = b * Math.sin (t);

            var ex = (a * a - b * b) * Math.pow (Math.cos (t), 3) / a;
            var ey = (b * b - a * a) * Math.pow (Math.sin (t), 3) / b;

            var r_x = x - ex;
            var r_y = y - ey;

            var qx = px - ex;
            var qy = py - ey;
            
            if (qx.is_nan ()) {
                error ("Didn't find closest point.");
            }

            var r = Math.hypot (r_y, r_x);
            var q = Math.hypot (qy, qx);

            var d_c = r * Math.asin ((r_x * qy - r_y * qx) / (r * q));
            var d_t = d_c / Math.sqrt (a * a + b * b - x * x - y * y);

            t += d_t;
            t = double.min (Math.PI / 2, double.max (0, t));
        }
        px = Math.copysign (a * Math.cos (t), Math.cos (an - angle));
        py = Math.copysign (b * Math.sin (t), Math.sin (an - angle));
        var sx = px / rx;
        var sy = py / ry;
        p_angle = Math.atan2 (sy, sx);
        return {center.x + Math.cos (angle) * px - Math.sin (angle) * py,
                center.y + Math.cos (angle) * py + Math.sin (angle) * px};
    }

    private Point point_from_angle (double a) {
        var dx = Math.cos (a);
        var dy = Math.sin (a);
        return {center.x + Math.cos (angle) * dx * rx - Math.sin (angle) * dy * ry,
                center.y + Math.cos (angle) * dy * ry + Math.sin (angle) * dx * rx};
    }

    public bool clicked (double x, double y, double tolerance) {
        // Have Cairo check if the point would be covered by
        // stroking the path by tolerance.
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, 1, 1);
        var context = new Cairo.Context(surface);
        context.set_line_width(tolerance);
        context.move_to(start.x, start.y);
        do_command(context);
        return context.in_stroke(x, y);
    }

    public void draw_controls (Cairo.Context cr, double zoom) {
        switch (segment_type) {
            case SegmentType.CURVE:
                cr.move_to (start.x, start.y);
                cr.line_to (p1.x, p1.y);
                cr.line_to (p2.x, p2.y);
                cr.line_to (end.x, end.y);
                cr.set_source_rgba(0, 0.5, 1, 0.8);
                cr.stroke ();
                cr.arc (p1.x, p1.y, 6 / zoom, 0, Math.PI * 2);
                cr.new_sub_path ();
                cr.arc (p2.x, p2.y, 6 / zoom, 0, Math.PI * 2);
                cr.new_sub_path ();
                break;
            case SegmentType.ARC:
                cr.move_to (topleft.x, topleft.y);
                cr.line_to (topright.x, topright.y);
                cr.line_to (bottomright.x, bottomright.y);
                cr.line_to (bottomleft.x, bottomleft.y);
                cr.close_path ();
                cr.new_sub_path ();
                cr.save ();
                cr.translate (center.x, center.y);
                cr.rotate (angle);
                cr.scale (rx, ry);
                cr.arc (0, 0, 1, end_angle, start_angle);
                cr.restore ();
                cr.set_source_rgba (0, 0.5, 1, 0.8);
                cr.stroke ();
                cr.arc (controller.x, controller.y, 6 / zoom, 0, Math.PI * 2);
                cr.new_sub_path ();
                cr.arc (topleft.x, topleft.y, 6 / zoom, 0, Math.PI * 2);
                cr.new_sub_path ();
                cr.arc (topright.x, topright.y, 6 / zoom, 0, Math.PI * 2);
                cr.new_sub_path ();
                cr.arc (bottomleft.x, bottomleft.y, 6 / zoom, 0, Math.PI * 2);
                cr.new_sub_path ();
                cr.arc (bottomright.x, bottomright.y, 6 / zoom, 0, Math.PI * 2);
                cr.new_sub_path ();
                cr.arc (center.x, center.y, 6 / zoom, 0, Math.PI * 2);
                cr.new_sub_path ();
                break;
            default:
                break;
        }

        cr.arc (end.x, end.y, 6 / zoom, 0, Math.PI * 2);
        cr.set_source_rgba (1, 0, 0, 0.9);
        cr.fill ();
    }

    public bool check_controls (double x, double y, double tolerance, out Handle? handle) {
        if ((x - end.x).abs () <= tolerance &&
            (y - end.y).abs () <= tolerance) {
            handle = new BaseHandle(this, "end", new Gee.ArrayList<ContextOption> ());
            return true;
        }
        switch (segment_type) {
            case CURVE:
                if ((x - p1.x).abs () <= tolerance &&
                    (y - p1.y).abs () <= tolerance) {
                    handle = new BaseHandle(this, "p1", new Gee.ArrayList<ContextOption> ());
                    return true;
                }
                if ((x - p2.x).abs () <= tolerance && 
                    (y - p2.y).abs () <= tolerance) {
                    handle = new BaseHandle(this, "p2", new Gee.ArrayList<ContextOption> ());
                    return true;
                }
                break;
            case ARC:
                if ((x - controller.x).abs () <= tolerance &&
                    (y - controller.y).abs () <= tolerance) {
                    handle = new BaseHandle(this, "controller", new Gee.ArrayList<ContextOption> ());
                    return true;
                }
                if ((x - topleft.x).abs () <= tolerance &&
                    (y - topleft.y).abs () <= tolerance) {
                    handle = new BaseHandle(this, "topleft", new Gee.ArrayList<ContextOption> ());
                    return true;
                }
                if ((x - topright.x).abs () <= tolerance &&
                    (y - topright.y).abs () <= tolerance) {
                    handle = new BaseHandle(this, "topright", new Gee.ArrayList<ContextOption> ());
                    return true;
                }
                if ((x - bottomleft.x).abs () <= tolerance &&
                    (y - bottomleft.y).abs () <= tolerance) {
                    handle = new BaseHandle(this, "bottomleft", new Gee.ArrayList<ContextOption> ());
                    return true;
                }
                if ((x - bottomright.x).abs () <= tolerance &&
                    (y - bottomright.y).abs () <= tolerance) {
                    handle = new BaseHandle(this, "bottomright", new Gee.ArrayList<ContextOption> ());
                    return true;
                }
                if ((x - center.x).abs () <= tolerance &&
                    (y - center.y).abs () <= tolerance) {
                    handle = new BaseHandle(this, "center", new Gee.ArrayList<ContextOption> ());
                    return true;
                }
                break;
            default:
                break;
        }

        handle = null;
        return false;
    }

    public override Gee.List<ContextOption> options () {
        var options = new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            // TODO: Add a delete segment button
            new ContextOption.action (_("Split Segment"), () => { request_split (this); })
        });

        if (segment_type == ARC) {
            options.add (new ContextOption.action (_("Flip Arc"), () => { reverse = !reverse; }));
        }

        var segment_type_options = new Gee.HashMap<string, int> ();
        segment_type_options.set (_("Line"), SegmentType.LINE);
        segment_type_options.set (_("Curve"), SegmentType.CURVE);
        segment_type_options.set (_("Arc"), SegmentType.ARC);
        options.add (new ContextOption.options (_("Change segment to:"), this, "segment_type", segment_type_options));
        return options;
    }
}
