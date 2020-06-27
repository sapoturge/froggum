public enum SegmentType {
    MOVE,
    CLOSE,
    LINE,
    CURVE,
    ARC
}

public class Segment : Object {
    public SegmentType segment_type; 

    // End points, used for all but CLOSE segments
    public double x { get; set; }
    public double y { get; set; }

    // Control points, used for CURVE segments
    public double x1 { get; set; }
    public double y1 { get; set; }
    public double x2 { get; set; }
    public double y2 { get; set; }

    // TODO: Arc control points


    // Constructors
    public Segment.close () {
        segment_type = CLOSE;
    }

    public Segment.move (double x, double y) {
        segment_type = MOVE;
        this.x = x;
        this.y = y;
    }

    public Segment.line (double x, double y) {
        segment_type = LINE;
        this.x = x;
        this.y = y;
    }

    public Segment.curve (double x1, double y1, double x2, double y2, double x, double y) {
        segment_type = CURVE;
        this.x = x;
        this.y = y;
        this.x1 = x1;
        this.y1 = y1;
        this.x2 = x2;
        this.y2 = y2;
    }

    // TODO: Arc constructor

    public void do_command (Cairo.Context cr) {
        switch (segment_type) {
            case CLOSE:
                cr.close_path();
                break;
            case MOVE:
                cr.move_to (x, y);
                break;
            case LINE:
                cr.line_to (x, y);
                break;
            case CURVE:
                cr.curve_to (x1, y1, x2, y2, x, y);
                break;
            case ARC:
                // TODO: Draw an arc
                break;
        }
    }
}
