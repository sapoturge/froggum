public class Handle : Object, Undoable {
    public Point point { get; set; }

    private Point last_point;

    public void begin (string prop, Value? val = null) {
        last_point = point;
    }

    public void finish (string prop) {
        var command = new Command ();
        command.add_value (this, prop, point, last_point);
        add_command (command);
    }
}
