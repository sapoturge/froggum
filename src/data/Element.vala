public abstract class Element : Object, Undoable {
    public virtual Pattern? stroke { get; set; }

    public virtual Pattern? fill { get; set; }

    private Transform _transform;
    public Transform transform {
        get { return _transform; }
        set {
            _transform = value;
            transform.update.connect (() => { update (); });
            transform.add_command.connect ((c) => { add_command (c); });
        }
     }

    public string title { get; set; }

    public bool visible { get; set; }

    public signal void update ();

    public signal void select (bool selected);

    protected void setup_signals () {
        stroke.update.connect (() => { update (); });
        fill.update.connect (() => { update (); });
        stroke.add_command.connect ((c) => { add_command (c); });
        fill.add_command.connect ((c) => { add_command (c); });

        notify.connect (() => { update (); });
        select.connect (() => {
            update ();
        });
    }

    protected Element.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        title = node->get_prop ("id");
        visible = true;
        fill = Pattern.get_from_text (node->get_prop ("fill"), patterns);
        stroke = Pattern.get_from_text (node->get_prop ("stroke"), patterns);
        transform = new Transform.from_string (node->get_prop ("transform"));

        setup_signals ();
    }

    public abstract void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false);

    public abstract void draw_controls (Cairo.Context cr, double zoom);

    public abstract void begin (string prop, Value? start_location);

    public abstract void finish (string prop);

    public abstract int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index, out Xml.Node* node);

    protected int add_standard_attributes (Xml.Node* node, Xml.Node* defs, int pattern_index) {
        node->new_prop ("id", title);

        if (fill != null) {
            var fill_text = fill.to_xml (defs, ref pattern_index);
            node->new_prop ("fill", fill_text);
        }

        if (stroke != null) {
            var stroke_text = stroke.to_xml (defs, ref pattern_index);
            node->new_prop ("stroke", stroke_text);
        }

        var transform_text = transform.to_string ();
        if (transform_text != null) {
            node->new_prop ("transform", transform_text);
        }

        return pattern_index;
    }

    public abstract Element copy ();

    public abstract void check_controls (double x, double y, double tolerance, out Undoable obj, out string prop);

    public abstract bool clicked (double x, double y, double tolerance, out Segment? segment);
}
