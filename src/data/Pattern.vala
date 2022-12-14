public enum PatternType {
    NONE,
    COLOR,
    LINEAR,
    RADIAL,
}

public class Pattern : Object, ListModel, Undoable {
    private Cairo.Pattern pattern;

    public PatternType pattern_type { get; set; }
    
    public Gdk.RGBA rgba { get; set; }

    public Point start { get; set; }
    public Point end { get; set; }
    
    private Point previous_start;
    private Point previous_end;
    private PatternType previous_pattern_type;
    private Gdk.RGBA previous_rgba;

    private Array<Stop> stops;
    
    public signal void update ();

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

    public static Pattern get_from_text (string? text, Gee.HashMap<string, Pattern> patterns) {
        if (text == null) {
            return new Pattern.none ();
        } else {
            Parser parser = new Parser (text);
            switch (parser.get_keyword ()) {
            case Keyword.URL:
                parser.match ("(");
                parser.match ("#");
                var name = parser.get_string ();
                return patterns.@get (name.substring (0, name.length - 1));
            case Keyword.NONE:
                return new Pattern.none ();
            case Keyword.RGB:
                var rgba = Gdk.RGBA ();
                parser.match ("(");
                rgba.red = parser.get_int () / 255.0;
                parser.match (",");
                rgba.green = parser.get_int () / 255.0;
                parser.match (",");
                rgba.blue = parser.get_int () / 255.0;
                rgba.alpha = 1.0;
                return new Pattern.color (rgba);
            case Keyword.RGBA:
                var rgba = Gdk.RGBA ();
                parser.match ("(");
                rgba.red = parser.get_int () / 255.0;
                parser.match (",");
                rgba.green = parser.get_int () / 255.0;
                parser.match (",");
                rgba.blue = parser.get_int () / 255.0;
                parser.match (",");
                rgba.alpha = parser.get_double ();
                return new Pattern.color (rgba);
             case Keyword.NOT_FOUND:
                 if (parser.match ("#")) {
                    var rgba = Gdk.RGBA ();
                    var color = parser.get_string (6);
                    var color_length = color.length / 3;
                    var red = 0;
                    var green = 0;
                    var blue = 0;
                    color.substring (1, color_length).scanf ("%x", &red);
                    color.substring (1 + color_length, color_length).scanf ("%x", &green);
                    color.substring (1 + color_length * 2, color_length).scanf ("%x", &blue);
                    if (color_length == 1) {
                        red *= 17;
                        green *= 17;
                        blue *= 17;
                    }
                    rgba.red = red / 255.0;
                    rgba.green = green / 255.0;
                    rgba.blue = blue / 255.0;
                    rgba.alpha = 1.0;
                    return new Pattern.color (rgba);
                } else {
                    parser.error ("Unknown pattern");
                    return new Pattern.none ();
                }
            default:
                parser.error ("Unknown pattern");
                return new Pattern.none ();
            }
        }
    }

    construct {
        stops = new Array<Stop> ();
        start = {0, 0};
        end = {5, 5};

        update.connect (() => { refresh_pattern (); });
        notify.connect (() => { update (); });
    }

    public Object? get_item (uint index) {
        if (index < stops.length) {
            return stops.index (index);
        }
        return null;
    }

    public Type get_item_type () {
        return typeof (Stop);
    }

    public uint get_n_items () {
        return stops.length;
    }

    private void refresh_pattern () {
        switch (pattern_type) {
            case NONE:
                pattern = new Cairo.Pattern.rgba (0, 0, 0, 0);
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
        cr.set_source (pattern);
    }

    public void apply_custom (Cairo.Context cr, Point start, Point end, PatternType? type=null) {
        if (type == null) {
            type = pattern_type;
        }
        Cairo.Pattern custom_pattern;
        switch (type) {
            case PatternType.COLOR:
                custom_pattern = pattern;
                break;
            case PatternType.LINEAR:
                custom_pattern = new Cairo.Pattern.linear (start.x, start.y, end.x, end.y);
                for (int i = 0; i < stops.length; i++) {
                    var s = stops.index (i);
                    custom_pattern.add_color_stop_rgba (s.offset, s.rgba.red, s.rgba.green, s.rgba.blue, s.rgba.alpha);
                }
                break;
            case PatternType.RADIAL:
                custom_pattern = new Cairo.Pattern.radial (start.x, start.y, 0, start.x, start.y, Math.hypot (end.x - start.x, end.y - start.y));
                for (int i = 0; i < stops.length; i++) {
                    var s = stops.index (i);
                    custom_pattern.add_color_stop_rgba (s.offset, s.rgba.red, s.rgba.green, s.rgba.blue, s.rgba.alpha);
                }
                break;
            case PatternType.NONE:
                var cx = start.x + (end.x - start.x) / 2;
                var cy = start.y + (end.y - start.y) / 2;
                var sx = cx - (end.y - start.y) / 2;
                var sy = cy - (end.x - start.x) / 2;
                var ex = cx + (end.y - start.y) / 2;
                var ey = cy + (end.x - start.x) / 2;
                custom_pattern = new Cairo.Pattern.linear (sx, ey, ex, sy);
                custom_pattern.add_color_stop_rgba (0.4, 0, 0, 0, 0);
                custom_pattern.add_color_stop_rgba (0.43, 1, 0, 0, 1);
                custom_pattern.add_color_stop_rgba (0.57, 1, 0, 0, 1);
                custom_pattern.add_color_stop_rgba (0.6, 0, 0, 0, 0);
                break;
            default: // This should never happen. Draws a red circle if it does
                var cx = (start.x + end.x) / 2;
                var cy = (start.y + end.y) / 2;
                var height = double.min(end.x - start.x, end.y - start.y) / 2;
                custom_pattern = new Cairo.Pattern.radial (cx, cy, height - 15, cx, cy, height - 5);
                custom_pattern.add_color_stop_rgba(0, 1, 1, 1, 1);
                custom_pattern.add_color_stop_rgba(0, 1, 0, 0, 1);
                custom_pattern.add_color_stop_rgba(1, 1, 0, 0, 1);
                custom_pattern.add_color_stop_rgba(1, 1, 1, 1, 1);
                break;
        }
        cr.set_source (custom_pattern);
    }

    public void add_stop (Stop stop) {
        stops.append_val (stop);
        stop.start = start;
        stop.end = end;
        bind_property ("start", stop, "start");
        bind_property ("end", stop, "end");
        stop.notify.connect (() => { update (); });
        stop.add_command.connect ((c) => { add_command (c); });
        items_changed (stops.length - 1, 0, 1);
        update ();
    }
    
    public void begin (string prop, Value? start_value = null) {
        switch (prop) {
            case "start":
                previous_start = start;
                break;
            case "end":
                previous_end = end;
                break;
            case "pattern_type":
                previous_pattern_type = pattern_type;
                break;
            case "rgba":
                previous_rgba = rgba;
                break;
        }
    }
    
    public void finish (string prop) {
        var command = new Command ();
        switch (prop) {
            case "start":
                command.add_value (this, "start", start, previous_start);
                break;
            case "end":
                command.add_value (this, "end", end, previous_end);
                break;
            case "pattern_type":
                command.add_value (this, "pattern_type", pattern_type, previous_pattern_type);
                break;
            case "rgba":
                command.add_value (this, "rgba", rgba, previous_rgba);
                break;
        }
        add_command (command);
    }
}

public class Stop : Object, Undoable {
    private double previous_offset;
    private Gdk.RGBA previous_rgba;
    
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

    public void begin (string prop, Value? start = null) {
        if (prop == "display" || prop == "offset") {
            previous_offset = offset;
        } else if (prop == "rgba") {
            previous_rgba = rgba;
        }
    }

    public void finish (string prop) {
        if (prop == "display" || prop == "offset") {
            var command = new Command ();
            command.add_value (this, "offset", offset, previous_offset);
            add_command (command);
        } else if (prop == "rgba") {
            var command = new Command ();
            command.add_value (this, "rgba", rgba, previous_rgba);
            add_command (command);
        }
    }

    public Point start { get; set; }
    public Point end { get; set; }

    public Stop (double offset, Gdk.RGBA rgba) {
        this.offset = offset;
        this.rgba = rgba;
    }
}
