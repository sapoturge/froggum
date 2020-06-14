public abstract class Segment {
    public abstract void do_command (Cairo.Context cr);
}

public class MoveSegment : Segment {
    private int x;
    private int y;

    public MoveSegment (int x, int y) {
        this.x = x;
        this.y = y;
    }

    public override void do_command (Cairo.Context cr) {
        cr.move_to (x, y);
    }
}

public class LineSegment : Segment {
    private int x;
    private int y;

    public LineSegment (int x, int y) {
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
