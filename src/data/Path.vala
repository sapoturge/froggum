public class Path : Object {
    public Segment root_segment;

    public Gdk.RGBA fill { get; set; }
    public Gdk.RGBA stroke { get; set; }

    public string title { get; set; }

    public bool visible { get; set; }

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

    public signal void update ();

    public signal void select (bool selected);

    public Path (Segment[] segments = {},
                 Gdk.RGBA fill = {0, 0, 0, 0},
                 Gdk.RGBA stroke = {0, 0, 0, 0},
                 string title = "Path") {
        this.root_segment = segments[0];
        this.fill = fill;
        this.stroke = stroke;
        this.title = title;
        visible = true;
        for (int i = 0; i < segments.length; i++) {
            segments[i].notify.connect (() => { update (); });
            segments[i].next = segments[(i + 1) % segments.length];
            segments[(i + 1) % segments.length].prev = segments[i];
            segments[i].next.start = segments[i].end;
        }
        select.connect (() => { update(); });
        notify.connect (() => { update(); });
    }

    public Path.from_string (string description, Gdk.RGBA fill, Gdk.RGBA stroke, string title) {
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
                var angle = get_number (description, ref i);
                var large_arc = get_number (description, ref i);
                var sweep = get_number (description, ref i);
                var x = get_number (description, ref i);
                var y = get_number (description, ref i);
                var x1 = (current_x - x) / 2 * Math.cos (angle) + Math.sin (angle) * (current_y - y) / 2;
                var y1 = -Math.sin (angle) * (current_x - x) / 2 + Math.cos (angle) * (current_y - y) / 2;
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
        this (segments, fill, stroke, title);
    }
        
    public Path copy () {
        Segment[] new_segments = { root_segment.copy () };
        var current_segment = root_segment.next;
        while (current_segment != root_segment) {
            new_segments += current_segment.copy ();
            current_segment = current_segment.next;
        }
        return new Path (new_segments, fill, stroke, title);
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

    public void draw (Cairo.Context cr, double width = 1, Gdk.RGBA? fill = null, Gdk.RGBA? stroke = null, bool always_draw = false) {
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
            fill = this.fill;
        }
        cr.set_source_rgba (fill.red,
                            fill.green,
                            fill.blue,
                            fill.alpha);
        cr.fill_preserve ();
        if (stroke == null) {
            stroke = this.stroke;
        }
        cr.set_source_rgba (stroke.red,
                            stroke.green,
                            stroke.blue,
                            stroke.alpha);
        cr.stroke ();
    }

    public void start_dragging (Point start_location) {
        last_reference = start_location;
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
}
