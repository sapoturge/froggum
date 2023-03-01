public class Handle : Object, Undoable {
    public Point point { get; set construct; }

    private Point last_point;

    public Handle (double x, double y) {
        Object (
            point: Point(x, y)
        );
    }

    public void begin (string prop, Value? val = null) {
        last_point = point;
    }

    public void finish (string prop) {
        var command = new Command ();
        command.add_value (this, prop, point, last_point);
        add_command (command);
    }
}
