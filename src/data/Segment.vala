public enum SegmentType {
    LINE,
    CURVE,
    ARC
}

public class Segment : Object {
    public SegmentType segment_type { get; set; }

    // End points, used for all segments
    public Point start { get; set; }
    public Point end { get; set; }

    // Control points, used for CURVE segments
    public Point p1 { get; set; }
    public Point p2 { get; set; }

    // SVG-based ARC control values
    public Point c { get; set; }
    public double rx { get; set; default = 16; }
    public double ry { get; set; default = 16; }
    public double angle { get; set; }
    public bool reverse { get; set; }

    // Control points for ARC segments
    public Point topleft {
        get {
            return {c.x - Math.cos (angle) * rx + Math.sin (angle) * ry,
                    c.y - Math.cos (angle) * ry + Math.sin (angle) * rx};
        }
        set {
            c.x = c.x;
        }
    }

    public Point topright {
        get {
            return {c.x + Math.cos (angle) * rx + Math.sin (angle) * ry,
                    c.y - Math.cos (angle) * ry - Math.sin (angle) * rx};
        }
    }

    public Point bottomleft {
        get {
            return {c.x - Math.cos (angle) * rx - Math.sin (angle) * ry,
                    c.y + Math.cos (angle) * ry + Math.sin (angle) * rx};
        }
    }
    
    public Point bottomright {
        get {
            return {c.x + Math.cos (angle) * rx - Math.sin (angle) * ry,
                    c.y + Math.cos (angle) * ry - Math.sin (angle) * rx};
        }
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
                double ox;
                double oy;
                cr.get_current_point (out ox, out oy);
                var start_angle = Math.atan (oy / ox);
                var end_angle = Math.atan ((end.x - c.x) / (end.y - c.y)) - angle;
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
