public class Group : Element, Container {
    public override Gtk.TreeListModel tree { get; set; }
    public override Element? selected_child { get; set; }
    public override bool transform_enabled {
        get {
            return selected_child == null;
        }
        set {}
    }

    public ModelUpdate updator {
        set {
            do_update (value);
        }
    }

    protected Gee.Map<Element, Container.ElementSignalManager> signal_managers { get; set; }

    construct {
        tree = new Gtk.TreeListModel (new ListStore (typeof (Element)), false, false, get_children);
        signal_managers = new Gee.HashMap<Element, Container.ElementSignalManager> ();
        selected_child = null;
    }

    public Group () {
        title = "Group";
        visible = true;
        fill = new Pattern.none ();
        stroke = new Pattern.none ();
        transform = new Transform.identity ();
   
        setup_signals ();

        select.connect ((selected) => {
            deselect ();
            selected_child = null;
        });
    }

    public Group.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        base.from_xml (node, patterns);

        load_elements (node, patterns);

        select.connect ((selected) => {
            deselect ();
            selected_child = null;
        });
    }
    
    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (visible || always_draw) {
            draw_children (cr);
        }
    }

    public override void draw_controls (Cairo.Context cr, double zoom) {
        draw_selected_child (cr, zoom);
    }

    public override void begin (string prop) {
        return;
    }
    
    public override void finish (string prop) {
        return;
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index) {
        Xml.Node* node = new Xml.Node (null, "g");

        pattern_index = add_standard_attributes (node, defs, pattern_index);

        pattern_index = save_children (node, defs, pattern_index);

        root->add_child (node);
        return pattern_index;
    }

    public override Element copy () {
        return new Group ();
    }

    public override bool check_controls (double x, double y, double tolerance, out Handle? handle) {
        if (selected_child != null) {
            return clicked_handle (x, y, tolerance, out handle);
        }

        if (check_standard_controls (x, y, tolerance, out handle)) {
            return true;
        }

        handle = null;
        return false;
    }

    public override bool clicked (double x, double y, double tolerance, out Element? element, out Segment? segment) {
        Handle handle;
        return clicked_child (x, y, tolerance, out element, out segment, out handle);
    }

    public Element get_element (Gtk.TreeIter iter) {
        return new Path ();
    }

    public override Gee.List<ContextOption> options () {
        // Groups have no inherent options.
        return new Gee.ArrayList<ContextOption> ();
    }
}
