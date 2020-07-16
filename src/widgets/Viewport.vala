public class Viewport : Gtk.DrawingArea, Gtk.Scrollable {
    private int _scroll_x;
    private int _scroll_y;
    private int base_x;
    private int base_y;
    private double _zoom = 1;
    private int width = 0;
    private int height = 0;

    private bool scrolling = false;

    private Path? selected_path;

    private Gdk.RGBA background;

    private Image _image;
    private Gtk.Adjustment horizontal;
    private Gtk.Adjustment vertical;

    public Point control_point { get; set; }
    private Binding point_binding;

    public Image image {
        get {
            return _image;
        }
        set {
            _image = value;
            _image.update.connect (() => {
                queue_draw_area (0, 0, width, height);
            });
            _image.path_selected.connect ((path) => {
                selected_path = path;
            });
            scroll_x = -_image.width / 2;
            scroll_y = -_image.height / 2;
        }
    }
            
    private int scroll_x {
        get {
            return _scroll_x;
        }
        set {
            _scroll_x = value;
            horizontal.value = -double.min (scroll_x + width / 2, 0);
        }
    }

    private int scroll_y {
        get {
            return _scroll_y;
        }
        set {
            _scroll_y = value;
            vertical.value = -double.min (scroll_y + height / 2, 0);
        }
    }

    private double zoom {
        get {
            return _zoom;
        }
        set {
            _zoom = value;
            hadjustment.upper = image.width * _zoom;
            vertical.upper = image.height * _zoom;
        }
    }

    public Gtk.Adjustment hadjustment {
        get {
            return horizontal;
        }
        set construct {
            horizontal = value;
            if (horizontal == null) {
                horizontal = new Gtk.Adjustment (0, 0, 0, 0, 0, 0);
            }
            // Set values
            if (image != null) {
                horizontal.lower = 0;
                horizontal.upper = image.width * zoom;
                horizontal.page_size = width;
                horizontal.page_increment = 1;
                horizontal.step_increment = 1;
            }
            // Bind events
            horizontal.value_changed.connect (() => {
                _scroll_x = -((int) horizontal.value + width / 2);
            });
        }
    }

    public Gtk.Adjustment vadjustment {
        get {
            return vertical;
        }
        set construct {
            vertical = value;
            if (vertical == null) {
                vertical = new Gtk.Adjustment (0, 0, 0, 0, 0, 0);
            }
            // Set values
            if (image != null) {
                vertical.lower = 0;
                vertical.upper = image.height;
                vertical.page_size = height;
                vertical.page_increment = 1;
                vertical.step_increment = 1;
            }
            // Bind events
            vertical.value_changed.connect (() => {
                _scroll_y = -((int) vertical.value + height / 2);
            });
        }
    }

    public Gtk.ScrollablePolicy hscroll_policy {
        get {
            return Gtk.ScrollablePolicy.NATURAL;
        }
        set {
        }
    }

    public Gtk.ScrollablePolicy vscroll_policy {
        get {
            return Gtk.ScrollablePolicy.NATURAL;
        }
        set {
        }
    }

    public Viewport () {}

    public Viewport.with_image (Image image) {
        this.image = image;
    }

    private double scale_x (double x) {
        return (x - width / 2 - scroll_x) / zoom;
    }

    private double scale_y (double y) {
        return (y - height / 2 - scroll_y) / zoom;
    }

    construct {
        background = {0.7, 0.7, 0.7, 1.0};

        set_size_request (320, 320);

        add_events (Gdk.EventMask.BUTTON_RELEASE_MASK |
                    Gdk.EventMask.BUTTON_PRESS_MASK |
                    Gdk.EventMask.BUTTON_MOTION_MASK |
                    Gdk.EventMask.SCROLL_MASK);

        draw.connect ((cr) => {
            cr.set_source_rgb (background.red, background.green, background.blue);
            cr.paint ();

            cr.translate (width / 2, height / 2);
            cr.translate (scroll_x, scroll_y);
            cr.save ();
            cr.scale (zoom, zoom);

            // Draw Image
            image.draw (cr);

            // Draw Grid
            if (zoom > 4) {
                cr.move_to (0, 0);
                cr.line_to (image.width, 0);
                cr.line_to (image.width, image.height);
                cr.line_to (0, image.height);
                cr.close_path ();
                cr.set_source_rgba (0.2, 0.2, 0.2, 0.5);
                cr.set_line_width (4 / zoom);
                cr.stroke ();
                for (int i = 1; i < image.width; i++) {
                    cr.move_to (i, 0);
                    cr.line_to (i, image.height);
                }
                for (int i = 1; i < image.height; i++) {
                    cr.move_to (0, i);
                    cr.line_to (image.width, i);
                }
                cr.set_line_width (2 / zoom);
                cr.stroke ();
            }

            // Draw Control Handles
            if (selected_path != null) {
                selected_path.draw (cr, 1 / zoom, {0, 0, 0, 0}, {1, 0, 0, 1}, true);
                
                cr.set_line_width (1 / zoom);
                var s = selected_path.root_segment;
                var first = true;
                while (first || s != selected_path.root_segment) {
                    first = false;
                    switch (s.segment_type) {
                        case SegmentType.CURVE:
                            cr.move_to (s.start.x, s.start.y);
                            cr.line_to (s.p1.x, s.p1.y);
                            cr.line_to (s.p2.x, s.p2.y);
                            cr.line_to (s.end.x, s.end.y);
                            cr.set_source_rgba (0, 0.5, 1, 0.8);
                            cr.stroke ();
                            cr.arc (s.p1.x, s.p1.y, 6 / zoom, 0, 3.14159265 * 2);
                            cr.new_sub_path ();
                            cr.arc (s.p2.x, s.p2.y, 6 / zoom, 0, 3.14159265 * 2);
                            cr.new_sub_path ();
                            break;
                        case SegmentType.LINE:
                            // Lines have no additional controls.
                            break;
                        case SegmentType.ARC:
                            cr.move_to (s.topleft.x, s.topleft.y);
                            cr.line_to (s.topright.x, s.topright.y);
                            cr.line_to (s.bottomright.x, s.bottomright.y);
                            cr.line_to (s.bottomleft.x, s.bottomleft.y);
                            cr.close_path ();
                            cr.set_source_rgba (0, 0.5, 1, 0.8);
                            cr.stroke ();
                            cr.arc (s.controller.x, s.controller.y, 6 / zoom, 0, 3.14159265 * 2);
                            cr.new_sub_path ();
                            cr.arc (s.topleft.x, s.topleft.y, 6 / zoom, 0, Math.PI * 2);
                            cr.new_sub_path ();
                            cr.arc (s.topright.x, s.topright.y, 6 / zoom, 0, Math.PI * 2);
                            cr.new_sub_path ();
                            cr.arc (s.bottomleft.x, s.bottomleft.y, 6 / zoom, 0, Math.PI * 2);
                            cr.new_sub_path ();
                            cr.arc (s.bottomright.x, s.bottomright.y, 6 / zoom, 0, Math.PI * 2);
                            cr.new_sub_path ();
                            break;
                    }
                    cr.arc (s.end.x, s.end.y, 6 / zoom, 0, 3.14159265 * 2);
                    cr.set_source_rgba (1, 0, 0, 0.9);
                    cr.fill ();
                    s = s.next;
                }
            }

            cr.restore();
            return false;
        });

        size_allocate.connect ((alloc) => {
            width = alloc.width;
            height = alloc.height;
            
            horizontal.page_size = width;
            vertical.page_size = height;

            // Recalculate values.
            scroll_x = scroll_x;
            scroll_y = scroll_y;
        });
        
        button_press_event.connect ((event) => {
            Path path = null;
            Segment segment = null;
            var clicked = clicked_path ((int) event.x, (int) event.y, out path, out segment);
            var x = scale_x (event.x);
            var y = scale_y (event.y);
            // Check for right-clicking on a segment
            if (event.button == 3) {
                if (clicked) {
                    path.select (true);
                }
                show_context_menu (segment, event);
                return false;
            }
            // Check for double-clicking on a path
            if (event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) {
                if (clicked) {
                    path.select (true);
                } else {
                    selected_path.select (false);
                }
                return false;
            }
            // Check for clicking on a control handle
            if (selected_path != null) {
                var s = selected_path.root_segment;
                var first = true;
                while (first || s != selected_path.root_segment) {
                    first = false;
                    if ((x - s.end.x).abs () <= 6 / zoom && (y - s.end.y).abs () <= 6 / zoom) {
                        point_binding = bind_property ("control_point", s, "end", BindingFlags.DEFAULT);
                        control_point = {x, y};
                        return false;
                    }
                    switch (s.segment_type) {
                        case SegmentType.CURVE:
                            if ((x - s.p1.x).abs () <= 6 / zoom && (y - s.p1.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control_point", s, "p1", BindingFlags.DEFAULT);
                                control_point = {x, y};
                                return false;
                            }
                            if ((x - s.p2.x).abs () <= 6 / zoom && (y - s.p2.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control_point", s, "p2", BindingFlags.DEFAULT);
                                control_point = {x, y};
                                return false;
                            }
                            break;
                        case SegmentType.ARC:
                            if ((x - s.controller.x).abs () <= 6 / zoom && (y - s.controller.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control_point", s, "controller", BindingFlags.DEFAULT);
                                control_point = {x, y};
                                return false;
                            }
                            if ((x - s.topleft.x).abs () <= 6 / zoom && (y - s.topleft.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control_point", s, "topleft", BindingFlags.DEFAULT);
                                control_point = {x, y};
                                return false;
                            }
                            if ((x - s.topright.x).abs () <= 6 / zoom && (y - s.topright.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control_point", s, "topright", BindingFlags.DEFAULT);
                                control_point = {x, y};
                                return false;
                            }
                            if ((x - s.bottomleft.x).abs () <= 6 / zoom && (y - s.bottomleft.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control_point", s, "bottomleft", BindingFlags.DEFAULT);
                                control_point = {x, y};
                                return false;
                            }
                            if ((x - s.bottomright.x).abs () <= 6 / zoom && (y - s.bottomright.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control_point", s, "bottomright", BindingFlags.DEFAULT);
                                control_point = {x, y};
                                return false;
                            }
                            break;
                    }
                    s = s.next;
                }
            }
            // Assume dragging
            scrolling = true;
            base_x = (int) event.x - scroll_x;
            base_y = (int) event.y - scroll_y;
            return false;
        });

        motion_notify_event.connect ((event) => {
            // Drag control handle (only changes if actually dragging something.)
            var new_x = scale_x (event.x);
            var new_y = scale_y (event.y);
            if ((new_x * 2 - Math.round (new_x * 2)).abs () < 6 / zoom) {
                new_x = Math.round (new_x * 2) / 2;
            }
            if ((new_y * 2 - Math.round (new_y * 2)).abs () < 6 / zoom) {
                new_y = Math.round (new_y * 2) / 2;
            }
            control_point = {new_x, new_y};
            // Drag entire segment?
            // Scroll
            if (scrolling) {
                scroll_x = (int) event.x - base_x;
                scroll_y = (int) event.y - base_y;
                queue_draw_area (0, 0, width, height);
            }
            return false;
        });

        button_release_event.connect ((event) => {
            // Stop scrolling, dragging, etc.
            point_binding.unbind ();
            scrolling = false;
            return false;
        });

        scroll_event.connect ((event) => {
            if (event.direction == Gdk.ScrollDirection.UP) {
                zoom *= 2;
                scroll_x *= 2;
                scroll_y *= 2;
            } else if (event.direction == Gdk.ScrollDirection.DOWN && zoom > 1) {
                zoom /= 2;
                scroll_x /= 2;
                scroll_y /= 2;
            }
            queue_draw_area (0, 0, width, height);
            return false;
        });
    }

    public bool get_border (out Gtk.Border border) {
        border = {0, 0, 0, 0};
        return true;
    }

    private bool clicked_path (int x, int y, out Path? path, out Segment? segment) {
        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
        unowned var data = surface.get_data ();
        var cr = new Cairo.Context (surface);
        cr.translate (width / 2, height / 2);
        cr.translate (scroll_x, scroll_y);
        cr.scale (zoom, zoom);
        cr.set_line_width (6 / zoom);
        cr.set_source_rgba (1, 1, 1, 1);
        foreach (Path _path in image.paths) {
            var _segment = _path.root_segment;
            var first = true;
            while (first || _segment != _path.root_segment) {
                first = false;
                cr.move_to (_segment.start.x, _segment.start.y);
                _segment.do_command (cr);
                cr.stroke ();
                // Check alpha of clicked pixel
                if (data [y * width * 4 + x * 4 + 3] > 0) {
                    path = _path;
                    segment = _segment;
                    return true;
                }
                _segment = _segment.next;
            }
        }
        path = null;
        segment = null;
        return false;
    }
        
    private void show_context_menu (Segment? segment, Gdk.EventButton event) {
        // Menu contents:
        // + Delete Path
        // ---
        // + Delete Segment
        // + Change segment to:
        //    + Line
        //    + Curve
        //    + Arc
        // + Flip Arc
        // + Split Path
        var menu_layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        var delete_path = new Gtk.Button ();
        delete_path.label = "Delete Path";
        delete_path.clicked.connect (() => {
            // TODO: Delete Path.
        });
        menu_layout.pack_start (delete_path, false, false, 0);

        if (segment != null) {
            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            menu_layout.pack_start (separator, false, false, 0);

            var delete_segment = new Gtk.Button ();
            delete_segment.label = "Delete Segment";
            delete_segment.clicked.connect (() => {
                // TODO: Delete segment.
            });
            menu_layout.pack_start (delete_segment, false, false, 0);

            var split_segment = new Gtk.Button ();
            split_segment.label = "Split Segment";
            split_segment.clicked.connect (() => {
                 selected_path.split_segment (segment);
            });
            menu_layout.pack_start (split_segment, false, false, 0);

            if (segment.segment_type == ARC) {
                var flip_arc = new Gtk.Button ();
                flip_arc.label = "Flip Arc";
                flip_arc.clicked.connect (() => {
                    segment.reverse = !segment.reverse;
                });
                menu_layout.pack_start (flip_arc, false, false, 0);
            }

            var separator2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            menu_layout.pack_start (separator2, false, false, 0);

            var switch_mode = new Gtk.Label ("Change segment to:");
            menu_layout.pack_start (switch_mode, false, false, 0);

            var line_mode = new Gtk.RadioButton.with_label (null, "Line");
            line_mode.toggled.connect (() => {
                if (line_mode.get_active ()) {
                    segment.segment_type = LINE;
                }
            });
            menu_layout.pack_start (line_mode, false, false, 0);

            var curve_mode = new Gtk.RadioButton.with_label_from_widget (line_mode, "Curve");
            curve_mode.toggled.connect (() => {
                if (curve_mode.get_active ()) {
                    segment.segment_type = CURVE;
                }
            });
            menu_layout.pack_start (curve_mode, false, false, 0);

            var arc_mode = new Gtk.RadioButton.with_label_from_widget (line_mode, "Arc");
            arc_mode.toggled.connect (() => {
                if (arc_mode.get_active ()) {
                    segment.segment_type = ARC;
                }
            });
            menu_layout.pack_start (arc_mode, false, false, 0);

            switch (segment.segment_type) {
                case LINE:
                    line_mode.active = true;
                    break;
                case CURVE:
                    curve_mode.active = true;
                    break;
                case ARC:
                    arc_mode.active = true;
                    break;
            }
        }

        menu_layout.show_all ();

        var menu = new Gtk.Popover (this);
        menu.add (menu_layout);

        menu.pointing_to = {(int) event.x - 5, (int) event.y - 5, 10, 10};

        menu.popup ();
    }
}
