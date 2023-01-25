public class Path : Element {
    public Segment root_segment;

    private Pattern _fill;
    public override Pattern? fill {
        get {
            return _fill;
        }
        set {
            _fill = value;
            fill.update.connect (() => { update (); });
            fill.add_command.connect ((c) => { add_command(c); });
        }
    }

    private Pattern _stroke;
    public override Pattern? stroke {
        get {
            return _stroke;
        }
        set {
            _stroke = value;
            stroke.update.connect (() => { update (); });
            stroke.add_command.connect ((c) => { add_command(c); });
        }
    }

    private Point last_reference;

    // I'll probably remove this entirely later.
    // public Point reference {
    //     set {
    //         var dx = value.x - last_reference.x;
    //         var dy = value.y - last_reference.y;
    //         var segment = root_segment;
    //         var first = true;
    //         while (first || segment != root_segment) {
    //             first = false;
    //             if (segment.segment_type == ARC) {
    //                 segment.topleft = {segment.topleft.x + dx, segment.topleft.y + dy};
    //                 segment.bottomright = {segment.bottomright.x + dx, segment.bottomright.y + dy};
    //             }
    //             segment = segment.next;
    //         }
    //         first = true;
    //         while (first || segment != root_segment) {
    //             first = false;
    //             if (segment.segment_type != ARC) {
    //                 if (segment.next.segment_type != ARC) {
    //                     segment.end = {segment.end.x + dx, segment.end.y + dy};
    //                 }
    //                 if (segment.segment_type == CURVE) {
    //                     segment.p1 = {segment.p1.x + dx, segment.p1.y + dy};
    //                     segment.p2 = {segment.p2.x + dx, segment.p2.y + dy};
    //                 }
    //             }
    //             segment = segment.next;
    //         }
    //         last_reference = value;
    //     }
    // }

    public Path (Segment[] segments = {},
                 Gdk.RGBA fill = {0, 0, 0, 0},
                 Gdk.RGBA stroke = {0, 0, 0, 0},
                 string title = "Path") {
        this.with_pattern (segments, new Pattern.color (fill), new Pattern.color (stroke), title);
    }

    public Path.with_pattern (Segment[] segments, Pattern fill, Pattern stroke, string title) {
        this.fill = fill;
        this.stroke = stroke;
        this.title = title;
        this.transform = new Transform.identity ();
        visible = true;
        set_segments (segments);
        setup_signals ();
    }

    public Path.from_string_with_pattern (string description, Pattern fill, Pattern stroke, string title) {
        parse_string (description);
        this.fill = fill;
        this.stroke = stroke;
        this.title = title;
        this.transform = new Transform.identity ();
        visible = true;
    }

    public Path.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns) {
        base.from_xml (node, patterns);
        parse_string (node->get_prop ("d"));
    }

    private void parse_string (string description) {
        var segments = new Segment[] {};
        int i = skip_whitespace (description, 0);
        double start_x = 0;
        double start_y = 0;
        double current_x = 0;
        double current_y = 0;
        while (i < description.length) {
            if (description[i] == 'M') {
                i += 1;
                i = skip_whitespace (description, i);
                start_x = get_number (description, ref i);
                start_y = get_number (description, ref i);
                current_x = start_x;
                current_y = start_y;
            } else if (description[i] == 'L') {
                i += 1;
                i = skip_whitespace (description, i);
                var x = get_number (description, ref i);
                var y = get_number (description, ref i);
                segments += new Segment.line (x, y);
                current_x = x;
                current_y = y;
            } else if (description[i] == 'C') {
                i += 1;
                i = skip_whitespace (description, i);
                var x1 = get_number (description, ref i);
                var y1 = get_number (description, ref i);
                var x2 = get_number (description, ref i);
                var y2 = get_number (description, ref i);
                var x = get_number (description, ref i);
                var y = get_number (description, ref i);
                segments += new Segment.curve (x1, y1, x2, y2, x, y);
                current_x = x;
                current_y = y;
            } else if (description[i] == 'A') {
                i += 1;
                i = skip_whitespace (description, i);
                var rx = get_number (description, ref i).abs ();
                var ry = get_number (description, ref i).abs ();
                var angle = get_number (description, ref i) * Math.PI / 180;
                var large_arc = get_number (description, ref i);
                var sweep = get_number (description, ref i);
                var x = get_number (description, ref i);
                var y = get_number (description, ref i);
                var x1 = (current_x - x) / 2 * Math.cos (angle) + Math.sin (angle) * (current_y - y) / 2;
                var y1 = -Math.sin (angle) * (current_x - x) / 2 + Math.cos (angle) * (current_y - y) / 2;
                var dt = (x1 * x1) / ( rx * rx) + (y1 * y1) / (ry * ry);
                if (dt > 1) {
                    rx = rx * Math.sqrt (dt);
                    ry = ry * Math.sqrt (dt);
                }
                var coefficient = Math.sqrt ((rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1) / (rx * rx * y1 * y1 + ry * ry * x1 * x1));
                if (large_arc == sweep) {
                    coefficient = -coefficient;
                }
                var cx1 = coefficient * rx * y1 / ry;
                var cy1 = -coefficient * ry * x1 / rx;
                var cx = cx1 * Math.cos (angle) - cy1 * Math.sin (angle) + (current_x + x) / 2;
                var cy = cx1 * Math.sin (angle) + cy1 * Math.cos (angle) + (current_y + y) / 2;
                segments += new Segment.arc (x, y, cx, cy, rx, ry, angle, (sweep == 0));
                current_x = x;
                current_y = y;
            } else if (description[i] == 'Z') {
                // Ends the path, back to the beginning.
                if (start_x != current_x || start_y != current_y) {
                    segments += new Segment.line (start_x, start_y);
                }
                i += 1;
            } else {
                i += 1;
                i = skip_whitespace (description, i);
            }
        }
        set_segments (segments);
    }

    private void set_segments (Segment[] segments) {
        root_segment = segments[0];
        for (int i = 0; i < segments.length; i++) {
            segments[i].notify.connect (() => { update (); });
            segments[i].add_command.connect ((c) => { add_command (c); });
            segments[i].next = segments[(i + 1) % segments.length];
        }
    }
        
    public string to_string () {
        var data = new string[] {"M %f %f".printf (root_segment.start.x, root_segment.start.y)};
        var s = root_segment;
        var first = true;
        while (first || s != root_segment) {
            first = false;
            data += s.command_text ();
            s = s.next;
        }
        data += "Z";
        return string.joinv (" ", data);
    }
        
    public override Element copy () {
        Segment[] new_segments = { root_segment.copy () };
        var current_segment = root_segment.next;
        while (current_segment != root_segment) {
            new_segments += current_segment.copy ();
            current_segment = current_segment.next;
        }
        return new Path.with_pattern (new_segments, fill, stroke, title);
    }

    public void split_segment (Segment segment) {
        Segment first;
        Segment last;
        segment.split (out first, out last);
        first.notify.connect (() => { update (); });
        last.notify.connect (() => { update (); });
        if (segment == root_segment) {
            root_segment = first;
        }
        update ();
    }

    public override void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
        if (!visible && !always_draw) {
            return;
        }
        cr.set_line_width (width);
        cr.move_to (root_segment.start.x, root_segment.start.y);
        var segment = root_segment;
        var first = true;
        while (first || segment != root_segment) {
            first = false;
            segment.do_command (cr);
            segment = segment.next;
        }
        cr.close_path ();
        if (fill == null) {
            this.fill.apply (cr);
        } else {
            cr.set_source_rgba (fill.red,
                                fill.green,
                                fill.blue,
                                fill.alpha);
        }
        cr.fill_preserve ();
        if (stroke == null) {
            this.stroke.apply (cr);
        } else {
            cr.set_source_rgba (stroke.red,
                                stroke.green,
                                stroke.blue,
                                stroke.alpha);
        }
        cr.stroke ();
    }

    public override void draw_controls (Cairo.Context cr, double zoom) {
        draw (cr, 1 / zoom, {0, 0, 0, 0}, {1, 0, 0, 1}, true);
        cr.set_line_width (1 / zoom);
        var s = root_segment;
        var first = true;
        while (first || s != root_segment) {
            first = false;
            s.draw_controls (cr, zoom);
            s = s.next;
        }

        fill.draw_controls (cr, zoom);
        stroke.draw_controls (cr, zoom);

        if (transform_enabled) {
            transform.draw_controls (cr, zoom);
        }
    }

    public override void begin (string prop, Value? start_location) {
        last_reference = *((Point*) start_location.peek_pointer ());
    }
    
    public override void finish (string prop) {
    }

    private static int skip_whitespace (string source, int start) {
        while (start < source.length && source[start] == ' ' || source[start] == '\t' || source[start] == '\n') {
            start += 1;
        }
        return start;
    }

    private static double get_number (string source, ref int start) {
        double result = 0;
        var negative = false;
        if (source[start] == '-') {
            negative = true;
            start++;
        }
        while (start < source.length && source[start] >= '0' && source[start] <= '9') {
            result *= 10;
            result += source[start] - '0';
            start += 1;
        }
        if (source[start] == '.') {
            start += 1;
            var power = -1;
            while (start < source.length && '0' <= source[start] && source[start] <= '9') {
                result += Math.pow (10, power) * (source[start] - '0');
                power -= 1;
                start += 1;
            }
        }
        if (negative) {
            result = -result;
        }
        start = skip_whitespace (source, start);
        return result;
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index, out Xml.Node* node) {
        node = new Xml.Node (null, "path");

        pattern_index = add_standard_attributes (node, defs, pattern_index);
        
        node->new_prop ("d", to_string ());

        root->add_child (node);

        return pattern_index;
    }

    public override void check_controls (double x, double y, double tolerance, out Undoable obj, out string prop) {
        if (fill.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        if (stroke.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        if (transform_enabled && transform.check_controls (x, y, tolerance, out obj, out prop)) {
            return;
        }

        var s = root_segment;
        var first = true;
        while (first || s != root_segment) {
            first = false;

            if (s.check_controls (x, y, tolerance, out obj, out prop)) {
                return;
            }
 
            s = s.next;
        }

        // TODO: check for clicking on the path itself
        obj = null;
        prop = null;
        return;
    }

    public override bool clicked (double x, double y, double tolerance, out Segment? segment) {
        segment = root_segment;
        var first = true;
        while (first || segment != root_segment) {
            if (segment.clicked (x, y, tolerance)) {
                return true;
            }
            first = false;
            segment = segment.next;
        }
        segment = null;
        return false;
    }
}
