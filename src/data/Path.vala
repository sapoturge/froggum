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
        set_segments (new Gee.ArrayList<PathSegment>.wrap (segments));
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
        var segments = new Gee.ArrayList<PathSegment> ();
        var parser = new Parser (description);
        var parsed = new StringBuilder ();
        var loaded_first = false;
        double start_x = 0;
        double start_y = 0;
        double current_x = 0;
        double current_y = 0;
        bool loaded_successfully = true;
        while (loaded_successfully && !parser.empty ()) {
            switch (parser.get_string (1)) {
            case "M":
                if (loaded_first) {
                    // Paths with disconnected segments aren't supported yet.
                    loaded_successfully = false;
                    break;
                }

                loaded_first = true;
                loaded_successfully = PathSegment.load_moves (parser, parsed, segments, out start_x, out start_y, ref current_x, ref current_y, false);
                break;
            case "L":
                loaded_successfully = PathSegment.load_lines (parser, parsed, segments, ref current_x, ref current_y, false);
                break;
            case "H":
                loaded_successfully = PathSegment.load_horizontal_lines (parser, parsed, segments, ref current_x, ref current_y, false);
                break;
            case "V":
                loaded_successfully = PathSegment.load_vertical_lines (parser, parsed, segments, ref current_x, ref current_y, false);
                break;
            case "C":
                loaded_successfully = PathSegment.load_curves (parser, parsed, segments, ref current_x, ref current_y, false);
                break;
            case "S":
                loaded_successfully = PathSegment.load_smooth_curves (parser, parsed, segments, ref current_x, ref current_y, false);
                break;
            case "Q":
                loaded_successfully = PathSegment.load_quadratics (parser, parsed, segments, ref current_x, ref current_y, false);
                break;
            case "T":
                loaded_successfully = PathSegment.load_smooth_quadratics (parser, parsed, segments, ref current_x, ref current_y, false);
                break;
            case "A":
                loaded_successfully = PathSegment.load_arcs (parser, parsed, segments, ref current_x, ref current_y, false);
                break;
            case "m":
                if (loaded_first) {
                    // Paths with disconnected segments aren't supported yet.
                    loaded_successfully = false;
                    break;
                }

                loaded_first = true;
                loaded_successfully = PathSegment.load_moves (parser, parsed, segments, out start_x, out start_y, ref current_x, ref current_y, true);
                break;
            case "l":
                loaded_successfully = PathSegment.load_lines (parser, parsed, segments, ref current_x, ref current_y, true);
                break;
            case "h":
                loaded_successfully = PathSegment.load_horizontal_lines (parser, parsed, segments, ref current_x, ref current_y, true);
                break;
            case "v":
                loaded_successfully = PathSegment.load_vertical_lines (parser, parsed, segments, ref current_x, ref current_y, true);
                break;
            case "c":
                loaded_successfully = PathSegment.load_curves (parser, parsed, segments, ref current_x, ref current_y, true);
                break;
            case "s":
                loaded_successfully = PathSegment.load_smooth_curves (parser, parsed, segments, ref current_x, ref current_y, true);
                break;
            case "q":
                loaded_successfully = PathSegment.load_quadratics (parser, parsed, segments, ref current_x, ref current_y, true);
                break;
            case "t":
                loaded_successfully = PathSegment.load_smooth_quadratics (parser, parsed, segments, ref current_x, ref current_y, true);
                break;
            case "a":
                loaded_successfully = PathSegment.load_arcs (parser, parsed, segments, ref current_x, ref current_y, true);
                break;
            case "Z":
            case "z":
                // Ends the path, back to the beginning.
                if (start_x != current_x || start_y != current_y) {
                    segments.add (new PathSegment.line (start_x, start_y));
                    current_x = start_x;
                    current_y = start_y;
                }

                parsed.append_printf ("Z ");
                break;
            default:
                loaded_successfully = false;
                break;
            }

            parser.skip_whitespace ();
        }

        if (segments.is_empty) {
            // Something went very wrong in loading.
            // This seems like a reasonable default.
            segments.add (new PathSegment.line (current_x, current_y));
            segments.add (new PathSegment.line (start_x, start_y));
            parsed.append_printf ("L %f, %f Z", current_x, current_y);
            loaded_successfully = false;
        }

        if (current_x != start_x || current_y != start_y) {
            // Open paths should be supported eventually, but aren't yet.
            segments.add (new PathSegment.line (start_x, start_y));
            parsed.append ("Z");
            loaded_successfully = false;
        }

        if (!loaded_successfully) {
            errors.offer (new Error.invalid_property ("path", "d", description, parsed.str));
        }

        set_segments (segments);
    }

    private void set_segments (Gee.List<PathSegment> segments) {
        root_segment = segments[0];
        for (int i = 0; i < segments.size; i++) {
            segments[i].notify.connect (() => { update (); });
            segments[i].add_command.connect ((c) => { add_command (c); });
            segments[i].next = segments[(i + 1) % segments.size];
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
