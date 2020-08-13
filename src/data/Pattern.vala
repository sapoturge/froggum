public enum PatternType {
    COLOR = 0,
    GRADIENT = 1
}

public class Pattern : Object {
    private Cairo.Pattern pattern;

    public PatternType pattern_type { get; private set; }

    private Gdk.RGBA _rgba;
    public Gdk.RGBA rgba {
        get {
            return _rgba;
        }
        set {
            _rgba = value;
            pattern_type = COLOR;
            pattern = new Cairo.Pattern.rgba (value.red, value.green, value.blue, value.alpha);
        }
    }

    public Pattern.color (Gdk.RGBA color) {
        rgba = color;
    }

    public void apply (Cairo.Context cr) {
        cr.set_source (pattern);
    }
}
