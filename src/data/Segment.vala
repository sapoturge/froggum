public abstract class Segment : Object, Undoable {
    public abstract Gee.List<ContextOption> options ();

    public abstract void begin (string prop, Value? value = null);
    public abstract void finish (string prop);
}
