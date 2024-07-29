public interface Undoable : Object {
    public signal void add_command (Command command);
    public abstract void begin (string prop);
    public abstract void finish (string prop);
    public abstract void cancel (string prop);
}
