public class Group : Element {
    public Group () {
        title = "Group";
        fill = new Pattern.none ();
        stroke = new Pattern.none ();
        fill.update.connect (() => { update (); });
        stroke.update.connect (() => { update (); });
    }
    
    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        return;
    }

    public override void draw_controls (Cairo.Context cr, double zoom) {
        return;
    }

    public override void begin (string prop, Value? start_location) {
        return;
    }
    
    public override void finish (string prop) {
        return;
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index) {
        return pattern_index;
    }

    public override Element copy () {
        return new Group ();
    }

    public override void check_controls (double x, double y, double tolerance, out Undoable obj, out string prop) {
        obj = null;
        prop = "";
        return;
    }

    public override bool clicked (double x, double y, double tolerance, out Segment? segment) {
        segment = null;
        return false;
    }
}
