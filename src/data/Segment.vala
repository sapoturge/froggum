public enum SegmentType {
    NONE,
    LINE,
    CURVE,
    ARC
}

public class Segment : Object, Undoable {
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

    public Segment prev { get; set; }
    private Segment _next;
    private Binding next_binding;
    public Segment next {
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
            
    // Constructors
    public Segment.line (double x, double y) {
        segment_type = LINE;
        this.end = {x, y};
    }

    public Segment.curve (double x1, double y1, double x2, double y2, double x, double y) {
        segment_type = CURVE;
        this.end = {x, y};
        this.p1 = {x1, y1};
        this.p2 = {x2, y2};
    }

    public Segment.arc (double x, double y, double xc, double yc, double rx, double ry, double angle, bool reverse) {
        segment_type = ARC;
        this.center = {xc, yc};
        this.rx = rx;
        this.ry = ry;
        this.angle = angle;
        this.reverse = reverse;
        this.end = {x, y};
    }
    
    public void begin (string property, Value? start_value = null) {
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
    
    public void finish (string property) {
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

    public Segment copy () {
        switch (segment_type) {
            case LINE:
                return new Segment.line (end.x, end.y);
            case CURVE:
                return new Segment.curve (p1.x, p1.y, p2.x, p2.y, end.x, end.y);
            case ARC:
                return new Segment.arc (end.x, end.y, center.x, center.y, rx, ry, angle, reverse);
        }
        return null;
    }


    public void split (out Segment first, out Segment last) {
        if (segment_type == LINE) {
            Point center = {(start.x + end.x) / 2, (start.y + end.y) / 2};
            first = new Segment.line (center.x, center.y);
            last = new Segment.line (end.x, end.y);
        } else if (segment_type == CURVE) {
            Point q1 = {(start.x + p1.x) / 2, (start.y + p1.y) / 2};
            Point q2 = {(p1.x + p2.x) / 2, (p1.y + p2.y) / 2};
            Point q3 = {(p2.x + end.x) / 2, (p2.y + end.y) / 2};
            Point r1 = {(q1.x + q2.x) / 2, (q1.y + q2.y) / 2};
            Point r2 = {(q2.x + q3.x) / 2, (q2.y + q3.y) / 2};
            Point s = {(r1.x + r2.x) / 2, (r1.y + r2.y) / 2};
            first = new Segment.curve (q1.x, q1.y, r1.x, r1.y, s.x, s.y);
            last = new Segment.curve (r2.x, r2.y, q3.x, q3.y, end.x, end.y);
        } else if (segment_type == ARC) {
            // ARC segments don't work very well together.
            first = this;
            last = new Segment.line (end.x, end.y);
        }
        prev.next = first;
        first.prev = prev;
        first.next = last;
        last.prev = first;
        last.next = next;
        next.prev = last;
        first.start = prev.end;
        last.start = first.end;
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
        switch (segment_type) {
            case LINE:
                var a = ((end.y - start.y) * x - (end.x - start.x) * y - start.x * end.y + end.x * start.y).abs ();
                var d = Math.sqrt ((end.y - start.y) * (end.y - start.y) + (end.x - start.x) * (end.x - start.x));
                return a / d <= tolerance;
        }
        return false;
    }
}
