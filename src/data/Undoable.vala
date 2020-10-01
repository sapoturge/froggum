public interface Undoable : Object {
    public signal void add_command (Command command);
    public abstract void begin (string prop, Value? initial_value = null);
    public abstract void finish (string prop);
}
