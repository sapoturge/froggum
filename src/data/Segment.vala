public abstract class Segment : Object, Undoable {
    public abstract Gee.List<ContextOption> options ();

    public abstract void begin (string prop);
    public abstract void finish (string prop);
    public abstract void cancel (string prop);

    public abstract void draw (Cairo.Context cr, double width, Gdk.RGBA stroke);
}
