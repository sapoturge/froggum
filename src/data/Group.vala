public class Group : Element, Container {
    public override Gtk.TreeListModel model { get; set; }

    construct {
        model = new Gtk.TreeListModel (new ListStore (typeof (Element)), false, false, get_children);
    }

    public Group () {
        title = "Group";
        visible = true;
        fill = new Pattern.none ();
        stroke = new Pattern.none ();
        transform = new Transform.identity ();
   
        setup_signals ();

        transform_enabled = true;
    }

    public Group.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        base.from_xml (node, patterns);

        load_elements (node, patterns);

        transform_enabled = true;
    }
    
    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        draw_children (cr);
    }

    public override void draw_controls (Cairo.Context cr, double zoom) {
        transform.draw_controls (cr, zoom);
        return;
    }

    public override void begin (string prop) {
        return;
    }
    
    public override void finish (string prop) {
        return;
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index) {
        var node = new Xml.Node (null, "g");

        pattern_index = add_standard_attributes (node, defs, pattern_index);

        pattern_index = save_children (node, defs, pattern_index);

        root->add_child (node);
        return pattern_index;
    }

    public override Element copy () {
        return new Group ();
    }

    public override void check_controls (double x, double y, double tolerance, out Undoable obj, out string prop) {
        if (transform.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        obj = null;
        prop = "";
        return;
    }

    public override bool clicked (double x, double y, double tolerance, out Segment? segment) {
        segment = null;
        return false;
    }

    public Element get_element (Gtk.TreeIter iter) {
        return new Path ();
    }

    public override Gee.List<ContextOption> options () {
        // Groups have no inherent options.
        return new Gee.ArrayList<ContextOption> ();
    }
}
