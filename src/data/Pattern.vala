public enum PatternType {
    NONE = 0,
    COLOR = 1,
    LINEAR = 2,
    RADIAL = 3,
}

public class Pattern : Object {
    private Cairo.Pattern pattern;

    private PatternType _pattern_type;
    public PatternType pattern_type {
        get {
            return _pattern_type;
        }
        set {
            _pattern_type = value;
        }
    }

    private Gdk.RGBA _rgba;
    public Gdk.RGBA rgba {
        get {
            return _rgba;
        }
        set {
            _rgba = value;
        }
    }

    public Point start { get; set; }
    public Point end { get; set; }

    private Array<Stop> stops;

    public Pattern.none () {
        pattern_type = NONE;
    }

    public Pattern.color (Gdk.RGBA color) {
        pattern_type = COLOR;
        rgba = color;
    }

    public Pattern.linear (Point start, Point end) {
        this.start = start;
        this.end = end;
        pattern_type = LINEAR;
    }

    public Pattern.radial (Point start, Point end) {
        this.start = start;
        this.end = end;
        pattern_type = RADIAL;
    }

    construct {
        stops = new Array<Stop> ();

        notify.connect (() => { refresh_pattern (); });
    }
        
    private void refresh_pattern () {
        switch (pattern_type) {
            case NONE:
                break;
            case COLOR:
                pattern = new Cairo.Pattern.rgba (rgba.red, rgba.green, rgba.blue, rgba.alpha);
                break;
            case LINEAR:
                pattern = new Cairo.Pattern.linear (start.x, start.y, end.x, end.y);
                for (int i = 0; i < stops.length; i++) {
                    var s = stops.index (i);
                    pattern.add_color_stop_rgba (s.offset, s.rgba.red, s.rgba.green, s.rgba.blue, s.rgba.alpha);
                }
                break;
            case RADIAL:
                pattern = new Cairo.Pattern.radial (start.x, start.y, 0, start.x, start.y, Math.hypot (start.x - end.x, start.y - end.y));
                for (int i = 0; i < stops.length; i++) {
                    var s = stops.index (i);
                    pattern.add_color_stop_rgba (s.offset, s.rgba.red, s.rgba.green, s.rgba.blue, s.rgba.alpha);
                }
                break;
         }
    }

    public void apply (Cairo.Context cr) {
        if (pattern_type != PatternType.NONE) {
            cr.set_source (pattern);
        }
    }
}

public class Stop : Object {
    public double offset { get; set; }
    public Gdk.RGBA rgba { get; set; }
    
    public Point display {
        get {
            return {start.x + (end.x - start.x) * offset,
                    start.y + (end.y - start.y) * offset};
        }
        set {
            var ds = (value.x - start.x) * (end.x - start.x) + (value.y - start.y) * (end.y - start.y);
            var s = ds / ((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y));
            offset = double.max (0, double.min (1, s));
        }
    }

    public Point start { get; set; }
    public Point end { get; set; }

    public Stop (double offset, Gdk.RGBA rgba) {
        this.offset = offset;
        this.rgba = rgba;
    }
}
