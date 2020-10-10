public abstract class Element : Object, Undoable {
    public virtual Pattern stroke { get; set; }

    public virtual Pattern fill { get; set; }

    public string title { get; set; }

    public bool visible { get; set; }

    public signal void update ();

    public signal void select (bool selected);

    public abstract void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false);

    public abstract void draw_controls (Cairo.Context cr, double zoom);

    public abstract void begin (string prop, Value? start_location);

    public abstract void finish (string prop);

    public abstract int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index);

    public abstract Element copy ();

    public abstract void check_controls (double x, double y, double tolerance, out Undoable obj, out string prop);

    public abstract bool clicked (double x, double y, double tolerance, out Segment? segment);
}
