public class Path : Element {
    public PathSegment root_segment;

    public Path (PathSegment[] segments = {},
                 Gdk.RGBA fill = {0, 0, 0, 0},
                 Gdk.RGBA stroke = {0, 0, 0, 0},
                 string title = "Path") {
        this.with_pattern (segments, new Pattern.color (fill), new Pattern.color (stroke), title);
    }

    public Path.with_pattern (PathSegment[] segments, Pattern fill, Pattern stroke, string title, Transform? transform = null) {
        this.fill = fill;
        this.stroke = stroke;
        this.title = title;
        if (transform == null) {
            this.transform = new Transform.identity ();
        } else {
            this.transform = transform;
            transform_enabled = !transform.is_identity ();
        }

        visible = true;
        set_segments (segments);
        setup_signals ();
    }

    public Path.from_string_with_pattern (string description, Pattern fill, Pattern stroke, string title, Gee.Queue<Error> errors) {
        parse_string (description, errors);
        this.fill = fill;
        this.stroke = stroke;
        this.title = title;
        this.transform = new Transform.identity ();
        visible = true;
    }

    public Path.from_xml (Xml.Node* node, Gee.HashMap<string, Pattern> patterns, Gee.Queue<Error> errors) {
        var actions = new Gee.HashMap<string, Element.AttributeLoaderFunc<string?>> ();
        actions.set ("d", (data_text, ref data, errors) => { data = data_text; });
        string? data = null;
        load_from_xml_actions (node, patterns, errors, actions, ref data);
        parse_string (data ?? "", errors);
    }

    private void parse_string (string description, Gee.Queue<Error> errors) {
        var segments = new PathSegment[] {};
        var parser = new Parser (description);
        var parsed = new StringBuilder ();
        var loaded_first = false;
        double start_x = 0;
        double start_y = 0;
        double current_x = 0;
        double current_y = 0;
        bool loaded_successfully = true;
        while (!parser.empty ()) {
            if (parser.match("M")) {
                if (loaded_first) {
                    // Paths with disconnected segments aren't supported yet.
                    loaded_successfully = false;
                    break;
                }

                loaded_first = true;

                if (!parser.get_double (out start_x)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out start_y)) {
                    loaded_successfully = false;
                    break;
                }

                current_x = start_x;
                current_y = start_y;
                parsed.append_printf ("M %f, %f ", start_x, start_y);
            } else if (parser.match ("L")) {
                double x, y;
                if (!parser.get_double (out x)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out y)) {
                    loaded_successfully = false;
                    break;
                }

                segments += new PathSegment.line (x, y);
                current_x = x;
                current_y = y;
                parsed.append_printf ("L %f, %f ", x, y);
            } else if (parser.match ("H")) {
                double x;
                if (!parser.get_double (out x)) {
                    loaded_successfully = false;
                    break;
                }

                segments += new PathSegment.line (x, current_y);
                current_x = x;
                parsed.append_printf ("H %f ", x);
            } else if (parser.match ("V")) {
                double y;
                if (!parser.get_double (out y)) {
                    loaded_successfully = false;
                    break;
                }

                segments += new PathSegment.line (current_x, y);
                current_y = y;
                parsed.append_printf ("V %f ", y);
            } else if (parser.match ("C")) {
                double x1, x2, y1, y2, x, y;
                if (!parser.get_double (out x1)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out y1)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out x2)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out y2)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out x)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out y)) {
                    loaded_successfully = false;
                    break;
                }

                segments += new PathSegment.curve (x1, y1, x2, y2, x, y);
                current_x = x;
                current_y = y;
                parsed.append_printf ("C %f, %f, %f, %f, %f, %f ", x1, y1, x2, y2, x, y);
            } else if (parser.match ("Q")) {
                double x1, y1, x, y;
                if (!parser.get_double (out x1)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out y1)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out x)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out y)) {
                    loaded_successfully = false;
                    break;
                }

                segments += new PathSegment.quadratic (x1, y1, x, y);
                current_x = x;
                current_y = y;
                parsed.append_printf ("Q %f, %f, %f, %f ", x1, y1, x, y);
            } else if (parser.match ("A")) {
                double rx, ry, angle;
                int large_arc, sweep;
                double x, y;
                if (!parser.get_double (out rx)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out ry)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out angle)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_int (out large_arc)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_int (out sweep)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out x)) {
                    loaded_successfully = false;
                    break;
                } else if (!parser.get_double (out y)) {
                    loaded_successfully = false;
                    break;
                }

                angle = angle * Math.PI / 180;

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
                segments += new PathSegment.arc (x, y, cx, cy, rx, ry, angle, (sweep == 0));
                current_x = x;
                current_y = y;
                parsed.append_printf ("A %f, %f, %f, %d, %d, %f, %f ", rx, ry, angle, large_arc, sweep, x, y);
            } else if (parser.match ("Z")) {
                // Ends the path, back to the beginning.
                if (start_x != current_x || start_y != current_y) {
                    segments += new PathSegment.line (start_x, start_y);
                }

                parsed.append_printf ("Z ");
            } else {
                loaded_successfully = false;
                break;
            }
        }

        if (segments.length == 0) {
            // Something went very wrong in loading.
            // This seems like a reasonable default.
            segments += new PathSegment.line (current_x, current_y);
            segments += new PathSegment.line (start_x, start_y);
            parsed.append_printf ("L %f, %f Z", current_x, current_y);
            loaded_successfully = false;
        }

        if (current_x != start_x || current_y != start_y) {
            // Open paths should be supported eventually, but aren't yet.
            segments += new PathSegment.line (start_x, start_y);
            parsed.append ("Z");
            loaded_successfully = false;
        }

        if (!loaded_successfully) {
            errors.offer (new Error.invalid_property ("path", "d", description, parsed.str));
        }

        set_segments (segments);
    }

    private void set_segments (PathSegment[] segments) {
        root_segment = segments[0];
        for (int i = 0; i < segments.length; i++) {
            segments[i].notify.connect (() => { update (); });
            segments[i].add_command.connect ((c) => { add_command (c); });
            segments[i].next = segments[(i + 1) % segments.length];
            segments[i].request_split.connect ((s) => {
                    split_segment((PathSegment) s);
            });
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
        PathSegment[] new_segments = { root_segment.copy () };
        var current_segment = root_segment.next;
        while (current_segment != root_segment) {
            new_segments += current_segment.copy ();
            current_segment = current_segment.next;
        }

        return new Path.with_pattern (new_segments, fill.copy (), stroke.copy (), "Copy of " + title, transform.copy ());
    }

    public void split_segment (PathSegment segment) {
        PathSegment first;
        PathSegment last;
        segment.split (out first, out last);
        first.notify.connect (() => { update (); });
        first.request_split.connect (split_segment);
        last.notify.connect (() => { update (); });
        last.request_split.connect (split_segment);
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
    }

    public override void begin (string prop) {
    }
    
    public override void finish (string prop) {
    }

    public override void cancel (string prop) {
    }

    public override Gee.List<ContextOption> options () {
        var opts = new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.deleter (_("Delete Path"), () => { request_delete(); }),
            new ContextOption.toggle (_("Show Transformation"), this, "transform_enabled")
        });
        if (transform_enabled && transform_applied) {
            opts.add (new ContextOption.action (_("Revert View"), () => {
                apply_transform (new Transform.identity(), null);
            }));
        } else if (transform_enabled) {
            opts.add (new ContextOption.action (_("Apply Transformation"), () => {
                apply_transform (transform.invert (), this);
                transform_applied = true;
            }));
        }

        return opts;
    }

    public override int add_svg (Xml.Node* root, Xml.Node* defs, int pattern_index) {
        Xml.Node* node = new Xml.Node (null, "path");

        pattern_index = add_standard_attributes (node, defs, pattern_index);
        
        node->new_prop ("d", to_string ());

        root->add_child (node);

        return pattern_index;
    }

    public override bool check_controls (double x, double y, double tolerance, out Handle? handle) {
        if (check_standard_controls (x, y, tolerance, out handle)) {
            return true;
        }

        var s = root_segment;
        var first = true;
        while (first || s != root_segment) {
            first = false;

            if (s.check_controls (x, y, tolerance, out handle)) {
                return true;
            }
 
            s = s.next;
        }

        handle = null;
        return false;
    }

    public override bool clicked (double x, double y, double tolerance, out Element? element, out Segment? segment) {
        var current_segment = root_segment;
        var first = true;
        while (first || current_segment != root_segment) {
            if (current_segment.clicked (x, y, tolerance)) {
                segment = current_segment;
                element = this;
                return true;
            }

            first = false;
            current_segment = current_segment.next;
        }

        element = null;
        segment = null;
        return false;
    }
}
