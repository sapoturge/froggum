public abstract class Handle : Object, Undoable {
    public abstract Point point { get; set; }
    protected abstract BaseHandle core { get; }
    public abstract Gee.List<ContextOption> options { get; }
    public abstract void begin (string prop);
    public abstract void finish (string prop);
    public abstract void cancel (string prop);
    public abstract bool same_point (Handle other);
    public signal void updated ();
}
