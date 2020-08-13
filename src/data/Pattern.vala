public class Pattern : Object {
    private Cairo.Pattern pattern;

    private Gdk.RGBA _base_color;
    public Gdk.RGBA base_color {
        get {
            return _base_color;
        }
        set {
            _base_color = value;
            pattern = new Cairo.Pattern.rgba (value.red, value.green, value.blue, value.alpha);
        }
    }

    public Pattern.color (Gdk.RGBA color) {
        base_color = color;
    }

    public void apply (Cairo.Context cr) {
        cr.set_source (pattern);
    }
}
