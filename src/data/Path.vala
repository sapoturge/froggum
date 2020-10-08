public class Path : Element {
    public Segment root_segment;

    private Pattern _fill;
    public override Pattern fill {
        get {
            return _fill;
        }
        set {
            _fill = value;
            fill.update.connect (() => { update (); });
        }
    }

    private Pattern _stroke;
    public override Pattern stroke {
        get {
            return _stroke;
        }
        set {
            _stroke = value;
            stroke.update.connect (() => { update (); });
        }
    }

    private Point last_reference;

    public Point reference {
        set {
            var dx = value.x - last_reference.x;
            var dy = value.y - last_reference.y;
            var segment = root_segment;
            var first = true;
            while (first || segment != root_segment) {
                first = false;
                if (segment.segment_type == ARC) {
                    segment.topleft = {segment.topleft.x + dx, segment.topleft.y + dy};
                    segment.bottomright = {segment.bottomright.x + dx, segment.bottomright.y + dy};
                }
                segment = segment.next;
            }
            first = true;
            while (first || segment != root_segment) {
                first = false;
                if (segment.segment_type != ARC) {
                    if (segment.next.segment_type != ARC) {
                        segment.end = {segment.end.x + dx, segment.end.y + dy};
                    }
                    if (segment.segment_type == CURVE) {
                        segment.p1 = {segment.p1.x + dx, segment.p1.y + dy};
                        segment.p2 = {segment.p2.x + dx, segment.p2.y + dy};
                    }
                }
                segment = segment.next;
            }
            last_reference = value;
        }
    }

    public Path (Segment[] segments = {},
                 Gdk.RGBA fill = {0, 0, 0, 0},
                 Gdk.RGBA stroke = {0, 0, 0, 0},
                 string title = "Path") {
        this.with_pattern (segments, new Pattern.color (fill), new Pattern.color (stroke), title);
    }

    public Path.with_pattern (Segment[] segments, Pattern fill, Pattern stroke, string title) {
        this.root_segment = segments[0];
        this.fill = fill;
        this.stroke = stroke;
        this.title = title;
        visible = true;
        for (int i = 0; i < segments.length; i++) {
            segments[i].notify.connect (() => { update (); });
            segments[i].add_command.connect ((c) => { add_command (c); });
            segments[i].next = segments[(i + 1) % segments.length];
        }
        select.connect (() => { update(); });
        notify.connect (() => { update(); });
        fill.add_command.connect ((c) => { add_command (c); });
        stroke.add_command.connect ((c) => { add_command (c); });
    }

    public Path.from_string (string description, Gdk.RGBA fill, Gdk.RGBA stroke, string title) {
        this.from_string_with_pattern (description, new Pattern.color (fill), new Pattern.color (stroke), title);
    }

    public Path.from_string_with_pattern (string description, Pattern fill, Pattern stroke, string title) {
        var segments = new Segment[] {};
        int i = skip_whitespace (description, 0);
        double start_x = 0;
        double start_y = 0;
        double current_x = 0;
        double current_y = 0;
        var num_segments = 0;
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
                var rx = get_number (description, ref i);
                var ry = get_number (description, ref i);
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
        this.with_pattern (segments, fill, stroke, title);
    }
    
    public string to_string () {
        var data = new string[] {"M %f %f".printf (root_segment.start.x, root_segment.start.y)};
        var s = root_segment;
        var first = true;
        while (first || s != root_segment) {
            first = false;
            switch (s.segment_type) {
                case LINE:
                    data += "L %f %f".printf (s.end.x, s.end.y);
                    break;
                case CURVE:
                    data += "C %f %f %f %f %f %f".printf (s.p1.x, s.p1.y, s.p2.x, s.p2.y, s.end.x, s.end.y);
                    break;
                case ARC:
                    var start = s.start_angle;
                    var end = s.end_angle;
                    int large_arc;
                    int sweep;
                    if (s.reverse) {
                        sweep = 0;
                    } else {
                        sweep = 1;
                    }
                    if (end - start > Math.PI) {
                        large_arc = 1 - sweep;
                    } else {
                        large_arc = sweep;
                    }
                    data += "A %f %f %f %d %d %f %f".printf (s.rx, s.ry, 180 * s.angle / Math.PI, large_arc, sweep, s.end.x, s.end.y);
                    break;
            }
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
            switch (s.segment_type) {
                case SegmentType.CURVE:
                    cr.move_to (s.start.x, s.start.y);
                    cr.line_to (s.p1.x, s.p1.y);
                    cr.line_to (s.p2.x, s.p2.y);
                    cr.line_to (s.end.x, s.end.y);
                    cr.set_source_rgba(0, 0.5, 1, 0.8);
                    cr.stroke ();
                    cr.arc (s.p1.x, s.p1.y, 6 / zoom, 0, Math.PI * 2);
                    cr.new_sub_path ();
                    cr.arc (s.p2.x, s.p2.y, 6 / zoom, 0, Math.PI * 2);
                    cr.new_sub_path ();
                    break;
                case SegmentType.ARC:
                    cr.move_to (s.topleft.x, s.topleft.y);
                    cr.line_to (s.topright.x, s.topright.y);
                    cr.line_to (s.bottomright.x, s.bottomright.y);
                    cr.line_to (s.bottomleft.x, s.bottomleft.y);
                    cr.close_path ();
                    cr.new_sub_path ();
                    cr.save ();
                    cr.translate (s.center.x, s.center.y);
                    cr.rotate (s.angle);
                    cr.scale (s.rx, s.ry);
                    cr.arc (0, 0, 1, s.end_angle, s.start_angle);
                    cr.restore ();
                    cr.set_source_rgba (0, 0.5, 1, 0.8);
                    cr.stroke ();
                    cr.arc (s.controller.x, s.controller.y, 6 / zoom, 0, Math.PI * 2);
                    cr.new_sub_path ();
                    cr.arc (s.topleft.x, s.topleft.y, 6 / zoom, 0, Math.PI * 2);
                    cr.new_sub_path ();
                    cr.arc (s.topright.x, s.topright.y, 6 / zoom, 0, Math.PI * 2);
                    cr.new_sub_path ();
                    cr.arc (s.bottomleft.x, s.bottomleft.y, 6 / zoom, 0, Math.PI * 2);
                    cr.new_sub_path ();
                    cr.arc (s.bottomright.x, s.bottomright.y, 6 / zoom, 0, Math.PI * 2);
                    cr.new_sub_path ();
                    cr.arc (s.center.x, s.center.y, 6 / zoom, 0, Math.PI * 2);
                    cr.new_sub_path ();
                    break;
            }

            cr.arc (s.end.x, s.end.y, 6 / zoom, 0, Math.PI * 2);
            cr.set_source_rgba (1, 0, 0, 0.9);
            cr.fill ();

            s = s.next;
        }

        if (fill.pattern_type == LINEAR || fill.pattern_type == RADIAL) {
            cr.move_to (fill.start.x, fill.start.y);
            cr.line_to (fill.end.x, fill.end.y);
            cr.set_source_rgba (0, 1, 0, 0.9);
            cr.stroke ();

            cr.arc (fill.start.x, fill.start.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
            cr.arc (fill.end.x, fill.end.y, 6 / zoom, 0, Math.PI * 2);
            cr.fill ();
           
            for (int i = 0; i < fill.get_n_items (); i++) {
                var stop = (Stop) fill.get_item (i);
                cr.arc (stop.display.x, stop.display.y, 6 / zoom, 0, Math.PI * 2);
                cr.set_source_rgba (0, 1, 0, 0.9);
                cr.fill ();

                cr.arc (stop.display.x, stop.display.y, 4 / zoom, 0, Math.PI * 2);
                cr.set_source_rgba (stop.rgba.red, stop.rgba.green, stop.rgba.blue, stop.rgba.alpha);
                cr.fill ();
            }
        }

        if (stroke.pattern_type == LINEAR || stroke.pattern_type == RADIAL) {
            cr.move_to (stroke.start.x, stroke.start.y);
            cr.line_to (stroke.end.x, stroke.end.y);
            cr.set_source_rgba (0, 1, 0, 0.9);
            cr.stroke ();

            cr.arc (stroke.start.x, stroke.start.y, 6 / zoom, 0, Math.PI * 2);
            cr.new_sub_path ();
            cr.arc (stroke.end.x, stroke.end.y, 6 / zoom, 0, Math.PI * 2);
            cr.fill ();
           
            for (int i = 0; i < stroke.get_n_items (); i++) {
                var stop = (Stop) stroke.get_item (i);
                cr.arc (stop.display.x, stop.display.y, 6 / zoom, 0, Math.PI * 2);
                cr.set_source_rgba (0, 1, 0, 0.9);
                cr.fill ();

                cr.arc (stop.display.x, stop.display.y, 4 / zoom, 0, Math.PI * 2);
                cr.set_source_rgba (stop.rgba.red, stop.rgba.green, stop.rgba.blue, stop.rgba.alpha);
                cr.fill ();
            }
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

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index) {
        var fill_text = "";
        var stroke_text = "";

        switch (fill.pattern_type) {
            case NONE:
                fill_text = "none";
                break;
            case COLOR:
                fill_text = "rgba(%d,%d,%d,%f)".printf ((int) (fill.rgba.red*255), (int) (fill.rgba.green*255), (int) (fill.rgba.blue*255), fill.rgba.alpha);
                break;
            case LINEAR:
                pattern_index++;
                fill_text = "url(#linearGrad%d)".printf (pattern_index);
                Xml.Node* fill_element = new Xml.Node (null, "linearGradient");
                fill_element->new_prop ("id", "linearGrad%d".printf (pattern_index));
                fill_element->new_prop ("x1", fill.start.x.to_string ());
                fill_element->new_prop ("y1", fill.start.y.to_string ());
                fill_element->new_prop ("x2", fill.end.x.to_string ());
                fill_element->new_prop ("y2", fill.end.y.to_string ());
                fill_element->new_prop ("gradientUnits", "userSpaceOnUse");
                
                for (int j = 0; j < fill.get_n_items (); j++) {
                    var stop = (Stop) fill.get_item (j);
                    Xml.Node* stop_element = new Xml.Node (null, "stop");
                    stop_element->new_prop ("offset", stop.offset.to_string ());
                    stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                    stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                    fill_element->add_child (stop_element);
                }
                
                defs->add_child (fill_element);
                break;
            case RADIAL:
                pattern_index++;
                fill_text = "url(#radialGrad%d)".printf (pattern_index);
                Xml.Node* fill_element = new Xml.Node (null, "radialGradient");
                fill_element->new_prop ("id", "radialGrad%d".printf (pattern_index));
                fill_element->new_prop ("cx", fill.start.x.to_string ());
                fill_element->new_prop ("cy", fill.start.y.to_string ());
                fill_element->new_prop ("fx", fill.start.x.to_string ());
                fill_element->new_prop ("fy", fill.start.y.to_string ());
                fill_element->new_prop ("r", Math.hypot (fill.end.x - fill.start.x, fill.end.y - fill.start.y).to_string ());
                fill_element->new_prop ("fr", "0");
                fill_element->new_prop ("gradientUnits", "userSpaceOnUse");
                
                for (int j = 0; j < fill.get_n_items (); j++) {
                    var stop = (Stop) fill.get_item (j);
                    Xml.Node* stop_element = new Xml.Node (null, "stop");
                    stop_element->new_prop ("offset", stop.offset.to_string ());
                    stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                    stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                    fill_element->add_child (stop_element);
                }
                
                defs->add_child (fill_element);
                break;
        }
        
        switch (stroke.pattern_type) {
            case NONE:
                stroke_text = "none";
                break;
            case COLOR:
                stroke_text = "rgba(%d,%d,%d,%f)".printf ((int) (stroke.rgba.red*255), (int) (stroke.rgba.green*255), (int) (stroke.rgba.blue*255), stroke.rgba.alpha);
                break;
            case LINEAR:
                pattern_index++;
                stroke_text = "url(#linearGrad%d)".printf (pattern_index);
                Xml.Node* stroke_element = new Xml.Node (null, "linearGradient");
                stroke_element->new_prop ("id", "linearGrad%d".printf (pattern_index));
                stroke_element->new_prop ("x1", stroke.start.x.to_string ());
                stroke_element->new_prop ("y1", stroke.start.y.to_string ());
                stroke_element->new_prop ("x2", stroke.end.x.to_string ());
                stroke_element->new_prop ("y2", stroke.end.y.to_string ());
                stroke_element->new_prop ("gradientUnits", "userSpaceOnUse");
                
                for (int j = 0; j < stroke.get_n_items (); j++) {
                    var stop = (Stop) stroke.get_item (j);
                    Xml.Node* stop_element = new Xml.Node (null, "stop");
                    stop_element->new_prop ("offset", stop.offset.to_string ());
                    stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                    stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                    stroke_element->add_child (stop_element);
                }
                
                defs->add_child (stroke_element);
                break;
            case RADIAL:
                pattern_index++;
                stroke_text = "url(#radialGrad%d)".printf (pattern_index);
                Xml.Node* stroke_element = new Xml.Node (null, "radialGradient");
                stroke_element->new_prop ("id", "radialGrad%d".printf (pattern_index));
                stroke_element->new_prop ("cx", stroke.start.x.to_string ());
                stroke_element->new_prop ("cy", stroke.start.y.to_string ());
                stroke_element->new_prop ("fx", stroke.start.x.to_string ());
                stroke_element->new_prop ("fy", stroke.start.y.to_string ());
                stroke_element->new_prop ("r", Math.hypot (stroke.end.x - stroke.start.x, stroke.end.y - stroke.start.y).to_string ());
                stroke_element->new_prop ("fr", "0");
                stroke_element->new_prop ("gradientUnits", "userSpaceOnUse");
                
                for (int j = 0; j < stroke.get_n_items (); j++) {
                    var stop = (Stop) stroke.get_item (j);
                    Xml.Node* stop_element = new Xml.Node (null, "stop");
                    stop_element->new_prop ("offset", stop.offset.to_string ());
                    stop_element->new_prop ("stop-color", "rgb(%d,%d,%d)".printf ((int) (stop.rgba.red*255), (int) (stop.rgba.green*255), (int) (stop.rgba.blue*255)));
                    stop_element->new_prop ("stop-opacity", stop.rgba.alpha.to_string ());
                    stroke_element->add_child (stop_element);
                }
                
                defs->add_child (stroke_element);
                break;
        }
        
        Xml.Node* element = new Xml.Node (null, "path");
        
        element->new_prop ("id", title);
        element->new_prop ("fill", fill_text);
        element->new_prop ("stroke", stroke_text);
        element->new_prop ("d", to_string ());
        root->add_child (element);

        return pattern_index;
    }

    public override void check_controls (double x, double y, double tolerance, out Undoable obj, out string prop) {
        var s = root_segment;
        var first = true;
        while (first || s != root_segment) {
            first = false;
            if ((x - s.end.x).abs () <= tolerance &&
                (y - s.end.y).abs () <= tolerance) {
                obj = s;
                prop = "end";
                return;
            }
            switch (s.segment_type) {
                case CURVE:
                    if ((x - s.p1.x).abs () <= tolerance &&
                        (y - s.p1.y).abs () <= tolerance) {
                        obj = s;
                        prop = "p1";
                        return;
                    }
                    if ((x - s.p2.x).abs () <= tolerance && 
                        (y - s.p2.y).abs () <= tolerance) {
                        obj = s;
                        prop = "p2";
                        return;
                    }
                    break;
                case ARC:
                    if ((x - s.controller.x).abs () <= tolerance &&
                        (y - s.controller.y).abs () <= tolerance) {
                        obj = s;
                        prop = "controller";
                        return;
                    }
                    if ((x - s.topleft.x).abs () <= tolerance &&
                        (y - s.topleft.y).abs () <= tolerance) {
                        obj = s;
                        prop = "topleft";
                        return;
                    }
                    if ((x - s.topright.x).abs () <= tolerance &&
                        (y - s.topright.y).abs () <= tolerance) {
                        obj = s;
                        prop = "topright";
                        return;
                    }
                    if ((x - s.bottomleft.x).abs () <= tolerance &&
                        (y - s.bottomleft.y).abs () <= tolerance) {
                        obj = s;
                        prop = "bottomleft";
                        return;
                    }
                    if ((x - s.bottomright.x).abs () <= tolerance &&
                        (y - s.bottomright.y).abs () <= tolerance) {
                        obj = s;
                        prop = "bottomright";
                        return;
                    }
                    if ((x - s.center.x).abs () <= tolerance &&
                        (y - s.center.y).abs () <= tolerance) {
                        obj = s;
                        prop = "center";
                        return;
                    }
                    break;
            }
            s = s.next;
        }

        if (fill.pattern_type == LINEAR || fill.pattern_type == RADIAL) {
            for (var i = 0; i < fill.get_n_items (); i++) {
                var stop = (Stop) fill.get_item (i);
                if ((x - stop.display.x).abs () <= tolerance &&
                    (y - stop.display.y).abs () <= tolerance) {
                    obj = stop;
                    prop = "display";
                    return;
                }
            }

            if ((x - fill.start.x).abs () <= tolerance &&
                (y - fill.start.y).abs () <= tolerance) {
                obj = fill;
                prop = "start";
                return;
            }

            if ((x - fill.end.x).abs () <= tolerance &&
                (y - fill.end.y).abs () <= tolerance) {
                obj = fill;
                prop = "end";
                return;
            }
        }

        if (stroke.pattern_type == LINEAR || stroke.pattern_type == RADIAL) {
            for (var i = 0; i < stroke.get_n_items (); i++) {
                var stop = (Stop) stroke.get_item (i);
                if ((x - stop.display.x).abs () <= tolerance &&
                    (y - stop.display.y).abs () <= tolerance) {
                    obj = stop;
                    prop = "display";
                    return;
                }
            }

            if ((x - stroke.start.x).abs () <= tolerance &&
                (y - stroke.start.y).abs () <= tolerance) {
                obj = stroke;
                prop = "start";
                return;
            }

            if ((x - stroke.end.x).abs () <= tolerance &&
                (y - stroke.end.y).abs () <= tolerance) {
                obj = stroke;
                prop = "end";
                return;
            }
        }

        // TODO: check for clicking on the path itself
        obj = null;
        return;
    }
}
