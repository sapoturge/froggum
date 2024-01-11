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
        pattern_type = NONE;  // For some reason, this doesn't trigger notify
        refresh_pattern ();
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
                int value;
                parser.match ("(");
                if (parser.get_int (out value)) {
                    rgba.red = value / 255.0f;
                }
                parser.match (",");
                if (parser.get_int (out value)) {
                    rgba.green = value / 255.0f;
                }
                parser.match (",");
                if (parser.get_int (out value)) {
                    rgba.blue = value / 255.0f;
                }
                rgba.alpha = 1.0f;
                return new Pattern.color (rgba);
            case Keyword.RGBA:
                var rgba = Gdk.RGBA ();
                int value;
                parser.match ("(");
                if (parser.get_int (out value)) {
                    rgba.red = value / 255.0f;
                }
                parser.match (",");
                if (parser.get_int (out value)) {
                    rgba.green = value / 255.0f;
                }
                parser.match (",");
                if (parser.get_int (out value)) {
                    rgba.blue = value / 255.0f;
                }
                parser.match (",");
                parser.get_float (out rgba.alpha);
                return new Pattern.color (rgba);
             case Keyword.NOT_FOUND:
                if (parser.match ("#")) {
                    var rgba = Gdk.RGBA ();
                    int red = 0, red2 = 0;
                    int green = 0, green2 = 0;
                    int blue = 0, blue2 = 0;
                    parser.get_digit (out red, 16, false);
                    parser.get_digit (out red2, 16, false);
                    parser.get_digit (out green, 16, false);
                    if (parser.get_digit (out green2, 16, false) &&
                        parser.get_digit (out blue, 16, false) &&
                        parser.get_digit (out blue2, 16, false)) {
                        red = red * 16 + red2;
                        green = green * 16 + green2;
                        blue = blue * 16 + blue2;
                    } else {
                        // Not enough digits for 6; must be three digits
                        blue = green * 17;
                        green = red2 * 17;
                        red = red * 17;
                    }

                    rgba.red = red / 255.0f;
                    rgba.green = green / 255.0f;
                    rgba.blue = blue / 255.0f;
                    rgba.alpha = 1.0f;
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
    
    public void begin (string prop) {
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

    public string to_xml (Xml.Node* defs, ref int pattern_index) {
        switch (pattern_type) {
            case NONE:
                return "none";
            case COLOR:
                return "rgba(%d,%d,%d,%f)".printf ((int) (rgba.red*255), (int) (rgba.green*255), (int) (rgba.blue*255), rgba.alpha);
            case LINEAR:
                pattern_index++;
                Xml.Node* element = new Xml.Node (null, "linearGradient");
                element->new_prop ("id", "linearGrad%d".printf (pattern_index));
                element->new_prop ("x1", start.x.to_string ());
                element->new_prop ("y1", start.y.to_string ());
                element->new_prop ("x2", end.x.to_string ());
                element->new_prop ("y2", end.y.to_string ());
                element->new_prop ("gradientUnits", "userSpaceOnUse");
                
                for (int j = 0; j < get_n_items (); j++) {
                    var stop = (Stop) get_item (j);
                    Xml.Node* stop_element = new Xml.Node (null, "stop");
                    stop_element->new_prop ("offset", stop.offset.to_string ());
                    stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                    stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                    element->add_child (stop_element);
                }
                
                defs->add_child (element);
                return "url(#linearGrad%d)".printf (pattern_index);
            case RADIAL:
                pattern_index++;
                Xml.Node* element = new Xml.Node (null, "radialGradient");
                element->new_prop ("id", "radialGrad%d".printf (pattern_index));
                element->new_prop ("cx", start.x.to_string ());
                element->new_prop ("cy", start.y.to_string ());
                element->new_prop ("fx", start.x.to_string ());
                element->new_prop ("fy", start.y.to_string ());
                element->new_prop ("r", Math.hypot (end.x - start.x, end.y - start.y).to_string ());
                element->new_prop ("fr", "0");
                element->new_prop ("gradientUnits", "userSpaceOnUse");
                
                for (int j = 0; j < get_n_items (); j++) {
                    var stop = (Stop) get_item (j);
                    Xml.Node* stop_element = new Xml.Node (null, "stop");
                    stop_element->new_prop ("offset", stop.offset.to_string ());
                    stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                    stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                    element->add_child (stop_element);
                }
                
                defs->add_child (element);
                return "url(#radialGrad%d)".printf (pattern_index);
            default:
                // Assume none
                return "none";
        }
    }

    public void draw_controls (Cairo.Context cr, double zoom) {
        if (pattern_type == LINEAR || pattern_type == RADIAL) {
            cr.set_line_width (1 / zoom);
            cr.move_to (start.x, start.y);
            cr.line_to (end.x, end.y);
            cr.set_source_rgba (0, 1, 0, 0.9);
            cr.stroke ();

            cr.arc (start.x, start.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
            cr.arc (end.x, end.y, 6 / zoom, 0, Math.PI * 2);
            cr.fill ();
           
            for (int i = 0; i < get_n_items (); i++) {
                var stop = (Stop) get_item (i);
                cr.arc (stop.display.x, stop.display.y, 6 / zoom, 0, Math.PI * 2);
                cr.set_source_rgba (0, 1, 0, 0.9);
                cr.fill ();

                cr.arc (stop.display.x, stop.display.y, 4 / zoom, 0, Math.PI * 2);
                cr.set_source_rgba (stop.rgba.red, stop.rgba.green, stop.rgba.blue, stop.rgba.alpha);
                cr.fill ();
            }
        }
    }

    public bool check_controls (double x, double y, double tolerance, out Undoable obj, out string prop) {
        if (pattern_type == LINEAR || pattern_type == RADIAL) {
            for (var i = 0; i < get_n_items (); i++) {
                var stop = (Stop) get_item (i);
                if ((x - stop.display.x).abs () <= tolerance &&
                    (y - stop.display.y).abs () <= tolerance) {
                    obj = stop;
                    prop = "display";
                    return true;
                }
            }

            if ((x - start.x).abs () <= tolerance &&
                (y - start.y).abs () <= tolerance) {
                obj = this;
                prop = "start";
                return true;
            }

            if ((x - end.x).abs () <= tolerance &&
                (y - end.y).abs () <= tolerance) {
                obj = this;
                prop = "end";
                return true;
            }
        }

        obj = null;
        prop = "";
        return false;
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

    public void begin (string prop) {
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
