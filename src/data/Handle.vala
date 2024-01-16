public abstract class Handle : Object {
    public abstract Point point { get; set; }
    public abstract Gee.List<ContextOption> options { get; }
}
