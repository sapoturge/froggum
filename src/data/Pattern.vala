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
    private bool initialized; // Flag to avoid unneeded default stops

    public struct StopUpdate {
        int position;
        Stop? stop;
    }

    public StopUpdate stop_update {
        set {
            if (value.stop != null) {
                stops.insert (value.position, value.stop);
                items_changed (value.position, 0, 1);
            } else {
                stops.remove_at (value.position);
                items_changed (value.position, 1, 0);
            }

            update ();
        }
    }

    private Gee.ArrayList<Stop> stops;

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
        initialized = false; // Don't create default stops; will be updated after stops are added
        pattern_type = LINEAR;
    }

    public Pattern.radial (Point start, Point end) {
        this.start = start;
        this.end = end;
        initialized = false; // Don't create default stops; will be updated after stops are added
        pattern_type = RADIAL;
    }

    public Pattern copy () {
        switch (pattern_type) {
        case NONE:
            return new Pattern.none ();
        case COLOR:
            return new Pattern.color (rgba);
        default:
            var pattern = new Pattern.linear (start, end);
            pattern.rgba = rgba;
            for (int i = 0; i < stops.size; i++) {
                var s = stops.@get (i);
                pattern.add_stop (s.copy ());
            }

            pattern.initialized = true;
            pattern.pattern_type = pattern_type;
            return pattern;
        }
    }

    public static Pattern? load_xml (Xml.Node* def, Gee.Queue<Error> errors) {
        var pattern = new Pattern.none ();

        for (Xml.Node* stop = def->children; stop != null; stop = stop->next) {
            var offset_data = stop->get_prop ("offset");
            double offset;
            if (offset_data == null) {
                offset = 0;
            } else if (offset_data.has_suffix ("%")) {
                offset = double.parse (offset_data.substring (0, offset_data.length - 1)) / 100;
            } else {
                offset = double.parse (offset_data);
            }

            var color = Gdk.RGBA ();
            color.parse (stop->get_prop ("stop-color") ?? "#000");
            var opacity = stop->get_prop ("stop-opacity");
            if (opacity != null) {
                if (opacity.has_suffix ("%")) {
                    color.alpha = float.parse (opacity.substring (0, opacity.length - 1)) / 100;
                } else {
                    color.alpha = float.parse (opacity);
                }
            }

            pattern.add_stop (new Stop (offset, color));
        }

        pattern.initialized = true;

        if (def->name == "linearGradient") {
            string? x1_text = null;
            string? x2_text = null;
            string? y1_text = null;
            string? y2_text = null;

            for (var property = def->properties; property != null; property = property->next) {
                var content = ((Xml.Node*) property)->get_content ();
                switch (property->name) {
                case "x1":
                    x1_text = content;
                    break;
                case "x2":
                    x2_text = content;
                    break;
                case "y1":
                    y1_text = content;
                    break;
                case "y2":
                    y2_text = content;
                    break;
                case "gradientUnits":
                    if (content != "userSpaceOnUse") {
                        errors.offer (new Error.invalid_property ("linearGradient", "gradientUnits", content));
                    }

                    break;
                case "id":
                    break; // We allow this property, but don't do anything with it here
                default:
                    errors.offer (new Error.unknown_attribute ("linearGradient", property->name, content));
                    break;
                }
            }

            if (x1_text == null) {
                errors.offer (new Error.missing_property ("linearGradient", "x1"));
                return null;
            } else if (y1_text == null) {
                errors.offer (new Error.missing_property ("linearGradient", "y1"));
                return null;
            } else if (x2_text == null) {
                errors.offer (new Error.missing_property ("linearGradient", "x2"));
                return null;
            } else if (y2_text == null) {
                errors.offer (new Error.missing_property ("linearGradient", "y2"));
                return null;
            }

            double x1;
            double y1;
            double x2;
            double y2;

            if (!double.try_parse (x1_text, out x1)) {
                errors.offer (new Error.invalid_property ("linearGradient", "x1", x1_text));
                return null;
            } else if (!double.try_parse (y1_text, out y1)) {
                errors.offer (new Error.invalid_property ("linearGradient", "y1", y1_text));
                return null;
            } else if (!double.try_parse (x2_text, out x2)) {
                errors.offer (new Error.invalid_property ("linearGradient", "x2", x2_text));
                return null;
            } else if (!double.try_parse (y2_text, out y2)) {
                errors.offer (new Error.invalid_property ("linearGradient", "y2", y2_text));
                return null;
            }

            pattern.start = { x1, y1 };
            pattern.end = { x2, y2 };

            pattern.pattern_type = LINEAR;
            return pattern;
        } else if (def->name == "radialGradient") {
            string? cx_text = null;
            string? cy_text = null;
            string? fx_text = null;
            string? fy_text = null;
            string? r_text = null;
            double scratch;

            for (var prop = def->properties; prop != null; prop = prop->next) {
                var content = ((Xml.Node*) prop)->get_content ();
                switch (prop->name) {
                case "cx":
                    cx_text = content;
                    break;
                case "cy":
                    cy_text = content;
                    break;
                case "r":
                    r_text = content;
                    break;
                case "fr":
                    if (!double.try_parse (content, out scratch) || scratch != 0.0) {
                        errors.offer (new Error.invalid_property ("radialGradient", "fr", content));
                    }

                    break;
                case "fx":
                    fx_text = content;
                    break;
                case "fy":
                    fy_text = content;
                    break;
                case "gradientUnits":
                    if (content != "userSpaceOnUse") {
                        errors.offer (new Error.invalid_property ("radialGradient", "gradientUnits", content));
                    }

                    break;
                case "id":
                    break; // We allow this, but don't do anything with it here
                default:
                    errors.offer (new Error.unknown_attribute ("radialGradient", prop->name, content));
                    break;
                }
            }

            if (cx_text == null) {
                errors.offer (new Error.missing_property ("radialGradient", "cx"));
                return null;
            } else if (cy_text == null) {
                errors.offer (new Error.missing_property ("radialGradient", "cy"));
                return null;
            } else if (r_text == null) {
                errors.offer (new Error.missing_property ("radialGradient", "r"));
                return null;
            }

            double cx;
            double cy;
            double r;

            if (!double.try_parse (cx_text, out cx)) {
                errors.offer (new Error.invalid_property ("radialGradient", "cx", cx_text));
                return null;
            } else if (!double.try_parse (cy_text, out cy)) {
                errors.offer (new Error.invalid_property ("radialGradient", "cy", cy_text));
                return null;
            } else if (!double.try_parse (r_text, out r)) {
                errors.offer (new Error.invalid_property ("radialGradient", "r", r_text));
                return null;
            }

            if (fx_text != null && (!double.try_parse (fx_text, out scratch) || scratch != cx)) {
                errors.offer (new Error.invalid_property ("radialGradient", "fx", fx_text));
                return null;
            } else if (fy_text != null && (!double.try_parse (fy_text, out scratch) || scratch != cy)) {
                errors.offer (new Error.invalid_property ("radialGradient", "fy", fy_text));
                return null;
            }

            pattern.start = { cx, cy };
            pattern.end = { cx + r, cy };

            pattern.pattern_type = RADIAL;
            return pattern;
        } else {
            errors.offer (new Error (ErrorKind.UNKNOWN_ELEMENT, def->name, "This was decoded as a pattern, but is not recognized as a pattern.\nElement: '%s'".printf (def->name)));
            return null;
        }
    }

    public static Pattern get_from_text (string? text, Gee.HashMap<string, Pattern> patterns) {
        if (text == null) {
            return new Pattern.none ();
        } else {
            Parser parser = new Parser (text);
            var rgba = parser.get_color();
            if (rgba != null) {
                return new Pattern.color (rgba);
            }

            var keyword = parser.get_keyword ();
            switch (keyword) {
            case Keyword.URL:
                parser.match ("(");
                parser.match ("#");
                var name = parser.get_string ();
                return patterns.@get (name.substring (0, name.length - 1)) ?? new Pattern.none ();
            case Keyword.NONE:
                return new Pattern.none ();
            default:
                parser.error ("Unknown pattern: %d".printf (keyword));
                return new Pattern.none ();
            }
        }
    }

    construct {
        stops = new Gee.ArrayList<Stop> ();
        start = {0, 0};
        end = {5, 5};
        initialized = true; // Set to false in gradient initializers

        update.connect (() => { refresh_pattern (); });
        notify.connect (() => { update (); });
    }

    public Object? get_item (uint index) {
        if (index < stops.size) {
            return stops.@get ((int) index);
        }
        return null;
    }

    public Type get_item_type () {
        return typeof (Stop);
    }

    public uint get_n_items () {
        return stops.size;
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
                if (initialized && stops.size == 0) {
                    initialized = false;
                    add_stop (new Stop (0.0, rgba));
                    add_stop (new Stop (1.0, rgba));
                    initialized = true;
                }

                pattern = new Cairo.Pattern.linear (start.x, start.y, end.x, end.y);
                for (int i = 0; i < stops.size; i++) {
                    var s = stops.@get (i);
                    pattern.add_color_stop_rgba (s.offset, s.rgba.red, s.rgba.green, s.rgba.blue, s.rgba.alpha);
                }
                break;
            case RADIAL:
                if (initialized && stops.size == 0) {
                    initialized = false; // Don't add commands for these stops
                    add_stop (new Stop (0.0, rgba));
                    add_stop (new Stop (1.0, rgba));
                    initialized = true;
                }

                pattern = new Cairo.Pattern.radial (start.x, start.y, 0, start.x, start.y, Math.hypot (start.x - end.x, start.y - end.y));
                for (int i = 0; i < stops.size; i++) {
                    var s = stops.@get (i);
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
                for (int i = 0; i < stops.size; i++) {
                    var s = stops.@get (i);
                    custom_pattern.add_color_stop_rgba (s.offset, s.rgba.red, s.rgba.green, s.rgba.blue, s.rgba.alpha);
                }
                break;
            case PatternType.RADIAL:
                custom_pattern = new Cairo.Pattern.radial (start.x, start.y, 0, start.x, start.y, Math.hypot (end.x - start.x, end.y - start.y));
                for (int i = 0; i < stops.size; i++) {
                    var s = stops.@get (i);
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
        stop.start = start;
        stop.end = end;
        bind_property ("start", stop, "start");
        bind_property ("end", stop, "end");
        stop.notify.connect (() => { update (); });
        stop.add_command.connect ((c) => {
            add_command (c);
            bool swapped = false;
            for (int i = 1; i < stops.size; i++) {
                for (int j = 1; j < stops.size; j++) {
                    Stop first = stops.@get(j-1);
                    Stop second = stops.@get(j);
                    if (first.offset > second.offset) {
                        swapped = true;
                        stops.@set (j, first);
                        stops.@set (j-1, second);
                    }
                }
            }
            if (swapped) {
                items_changed (0, stops.size, stops.size);
            }
        });

        var index = stops.size / 2;
        var lower = 0;
        var upper = stops.size - 1;
        while (upper > lower) {
            if (stops.@get (index).offset < stop.offset) {
                lower = index + 1;
            } else {
                upper = index - 1;
            }

            index = (upper + lower) / 2;
        }

        var insert_update = StopUpdate () {
            position = index,
            stop = stop,
        };

        if (initialized) {
            // Don't add commands for adding stops when loading or for the default stops
            var command = new Command ();
            var remove_update = StopUpdate () {
                position = index,
                stop = null,
            };
            command.add_value (this, "stop_update", insert_update, remove_update);
            add_command (command);
        }

        stop_update = insert_update;
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

    public void cancel (string prop) {
        switch (prop) {
            case "start":
                start = previous_start;
                break;
            case "end":
                end = previous_end;
                break;
            case "pattern_type":
                pattern_type = previous_pattern_type;
                break;
            case "rgba":
                rgba = previous_rgba;
                break;
        }
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

    public bool check_controls (double x, double y, double tolerance, out Handle? handle) {
        if (pattern_type == LINEAR || pattern_type == RADIAL) {
            for (var i = 0; i < get_n_items (); i++) {
                var stop = (Stop) get_item (i);
                if ((x - stop.display.x).abs () <= tolerance &&
                    (y - stop.display.y).abs () <= tolerance) {
                    var opts = new Gee.ArrayList<ContextOption> ();
                    opts.add (new ContextOption.deleter (_("Delete Stop"), () => { delete_stop (stop); }));
                    opts.add (new ContextOption.color (_("Change Color"), stop, "rgba"));
                    handle = new BaseHandle(stop, "display", opts);
                    return true;
                }
            }

            if ((x - start.x).abs () <= tolerance &&
                (y - start.y).abs () <= tolerance) {
                handle = new BaseHandle(this, "start", new Gee.ArrayList<ContextOption> ());
                return true;
            }

            if ((x - end.x).abs () <= tolerance &&
                (y - end.y).abs () <= tolerance) {
                handle = new BaseHandle(this, "end", new Gee.ArrayList<ContextOption> ());
                return true;
            }
        }

        handle = null;
        return false;
    }

    public bool clicked (double x, double y, double tolerance, out Segment? segment) {
        if (pattern_type == LINEAR || pattern_type == RADIAL) {
            if ((x - start.x).abs () <= tolerance &&
                (y - start.y).abs () <= tolerance) {
                segment = new PatternSegment (this, 0.0);
                return true;
            }

            if ((x - end.x).abs () <= tolerance &&
                (y - end.y).abs () <= tolerance) {
                segment = new PatternSegment(this, 1.0);
                return true;
            }

            var ds = (x - start.x) * (end.x - start.x) + (y - start.y) * (end.y - start.y);
            var aligned_offset = ds / ((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y));
            if (0 < aligned_offset && aligned_offset < 1) {
                Point inner_point = { start.x + aligned_offset * (end.x - start.x), start.y + aligned_offset * (end.y - start.y) };
                if (inner_point.dist ({x, y}) <= tolerance) {
                    segment = new PatternSegment (this, aligned_offset);
                    return true;
                }
            }
        }

        segment = null;
        return false;
    }

    private void delete_stop (Stop stop) {
        var index = stops.index_of (stop);
        if (index < 0) {
            return; // Not in the list; doesn't need to be removed
        }

        var command = new Command ();
        var delete_update = StopUpdate () {
            position = index,
            stop = null,
        };
        var replace_update = StopUpdate () {
            position = index,
            stop = stop,
        };
        stop_update = delete_update;
        command.add_value (this, "stop_update", delete_update, replace_update);
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

    public void cancel (string prop) {
        if (prop == "display" || prop == "offset") {
            offset = previous_offset;
        } else if (prop == "rgba") {
            rgba = previous_rgba;
        }
    }

    public Point start { get; set; }
    public Point end { get; set; }

    public Stop (double offset, Gdk.RGBA rgba) {
        this.offset = offset;
        this.rgba = rgba;
    }

    public Stop copy () {
        return new Stop (offset, rgba);
    }
}
