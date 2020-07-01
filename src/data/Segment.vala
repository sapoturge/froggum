public enum SegmentType {
    LINE,
    CURVE,
    ARC
}

public class Segment : Object {
    private static ParamSpec start_property;

    public SegmentType segment_type { get; set; }
    
    // End points, used for all segments
    private Point _start;
    private Point _end;
    public Point start {
        get {
            return _start;
        }
        set {
            if (segment_type == ARC) {
                var a = Math.atan2 (value.y - c.y, value.x - c.x) - angle;
                var r_x = rx * Math.cos (a);
                var r_y = ry * Math.sin (a);
                value.x = c.x + Math.cos (angle) * r_x - Math.sin (angle) * r_y;
                value.y = c.y + Math.cos (angle) * r_y + Math.sin (angle) * r_x;
                start_angle = a;
            }
            _start = value;
        }
    }
            
    public Point end {
        get {
            return _end;
        }
        set {
            if (segment_type == ARC) {
                var a = Math.atan2 (value.y - c.y, value.x - c.x) - angle;
                var r_x = rx * Math.cos (a);
                var r_y = ry * Math.sin (a);
                _end = {c.x + Math.cos (angle) * r_x - Math.sin (angle) * r_y,
                        c.y + Math.cos (angle) * r_y + Math.sin (angle) * r_x};
                end_angle = a;
            } else {
                _end = value;
            }
        }
    }

    // Control points, used for CURVE segments
    public Point p1 { get; set; }
    public Point p2 { get; set; }

    // SVG-based ARC control values
    public Point c { get; set; }
    public double rx { get; set; default = 16; }
    public double ry { get; set; default = 16; }
    public double angle { get; set; }
    public bool reverse { get; set; }
    // Easier to use and update than just points
    private double start_angle;
    private double end_angle;

    // Control points for ARC segments
    public Point topleft {
        get {
            return {c.x - Math.cos (angle) * rx + Math.sin (angle) * ry,
                    c.y - Math.cos (angle) * ry - Math.sin (angle) * rx};
        }
        set {
            c = {(value.x + bottomright.x) / 2, (value.y + bottomright.y) / 2};
            var a = Math.atan2 (value.y - c.y, value.x - c.x);
            var d = Math.sqrt (Math.pow (value.x - c.x, 2) + Math.pow (value.y - c.y, 2));
            rx = d * Math.cos (Math.PI + a - angle);
            ry = d * Math.sin (Math.PI + a - angle);
            start = start;
            end = end;
        }
    }

    public Point topright {
        get {
            return {c.x + Math.cos (angle) * rx + Math.sin (angle) * ry,
                    c.y - Math.cos (angle) * ry + Math.sin (angle) * rx};
        }
    }

    public Point bottomleft {
        get {
            return {c.x - Math.cos (angle) * rx - Math.sin (angle) * ry,
                    c.y + Math.cos (angle) * ry - Math.sin (angle) * rx};
        }
    }
    
    public Point bottomright {
        get {
            return {c.x + Math.cos (angle) * rx - Math.sin (angle) * ry,
                    c.y + Math.cos (angle) * ry + Math.sin (angle) * rx};
        }
    }

    public Point controller {
        get {
            return {c.x + Math.cos (angle) * (ry + 5),
                    c.y + Math.sin (angle) * (ry + 5)};
        }
        set {
            angle = Math.atan2 (value.y - c.y, value.x - c.x);
        }
    }
            
    static construct {
        Type segment_type = typeof (Segment);
        var cls = (ObjectClass) segment_type.class_ref ();
        start_property = cls.find_property ("start");
        print ("%s\n", start_property.get_nick ());
    }

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
        this.end = {x, y};
        this.c = {xc, yc};
        this.rx = rx;
        this.ry = ry;
        this.angle = angle;
        this.reverse = reverse;
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
                cr.translate (c.x, c.y);
                cr.scale (rx, ry);
                cr.rotate (angle);
                // var start_angle = Math.atan2 (start.y - c.y, start.x - c.x) - angle;
                // var end_angle = Math.atan2 (end.y - c.y, end.x - c.x) - angle;
                if (reverse) {
                    cr.arc_negative (0, 0, 1, start_angle, end_angle);
                } else {
                    cr.arc (0, 0, 1, start_angle, end_angle);
                }
                cr.restore ();
                break;
        }
    }
}
