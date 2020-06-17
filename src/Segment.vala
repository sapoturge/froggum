public abstract class Segment {
    public abstract void do_command (Cairo.Context cr);
}

public class MoveSegment : Segment {
    private double x;
    private double y;

    public MoveSegment (double x, double y) {
        this.x = x;
        this.y = y;
    }

    public override void do_command (Cairo.Context cr) {
        cr.move_to (x, y);
    }
}

public class LineSegment : Segment {
    private double x;
    private double y;

    public LineSegment (double x, double y) {
        this.x = x;
        this.y = y;
    }
    
    public override void do_command (Cairo.Context cr) {
        cr.line_to (x, y);
    }
}

public class ClosePathSegment : Segment {
    public override void do_command (Cairo.Context cr) {
        cr.close_path ();
    }
}
