public abstract class Handle : Object, Undoable {
    public abstract Point point { get; set; }
    public abstract Gee.List<ContextOption> options { get; }
    public abstract void begin (string prop);
    public abstract void finish (string prop);
}
