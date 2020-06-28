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

    public double control_x { get; set; }
    public double control_y { get; set; }
    private Binding x_binding;
    private Binding y_binding;

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

            // Draw Control Handles
            if (selected_path != null) {
                selected_path.draw (cr, 1 / zoom, {0, 0, 0, 0}, {1, 0, 0, 1}, true);
                
                cr.set_line_width (1 / zoom);
                var last_x = 0.0;
                var last_y = 0.0;
                foreach (Segment s in selected_path.segments) {
                    switch (s.segment_type) {
                        case SegmentType.CURVE:
                            cr.move_to (last_x, last_y);
                            cr.line_to (s.x1, s.y1);
                            cr.line_to (s.x2, s.y2);
                            cr.line_to (s.x, s.y);
                            cr.set_source_rgba (0, 0.5, 1, 0.8);
                            cr.stroke ();
                            cr.arc (s.x1, s.y1, 6 / zoom, 0, 3.14159265 * 2);
                            cr.new_sub_path ();
                            cr.arc (s.x2, s.y2, 6 / zoom, 0, 3.14159265 * 2);
                            cr.new_sub_path ();
                            // Intentional fall-through
                        case SegmentType.MOVE:
                        case SegmentType.LINE:
                            cr.arc (s.x, s.y, 6 / zoom, 0, 3.14159265 * 2);
                            cr.set_source_rgba (1, 0, 0, 0.9);
                            cr.fill ();
                            last_x = s.x;
                            last_y = s.y;
                            break;
                        case SegmentType.CLOSE:
                            // Close segments have nothing to edit.
                            break;
                        case SegmentType.ARC:
                            // TODO: Draw Handles for Arc
                            break;
                     }
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
                foreach (Segment s in selected_path.segments) {
                    switch (s.segment_type) {
                        case SegmentType.CURVE:
                            if ((x - s.x1).abs () <= 6 / zoom && (y - s.y1).abs () <= 6 / zoom) {
                                x_binding = bind_property ("control_x", s, "x1", BindingFlags.DEFAULT);
                                y_binding = bind_property ("control_y", s, "y1", BindingFlags.DEFAULT);
                                control_x = x;
                                control_y = y;
                                return false;
                            }
                            if ((x - s.x2).abs () <= 6 / zoom && (y - s.y2).abs () <= 6 / zoom) {
                                x_binding = bind_property ("control_x", s, "x2", BindingFlags.DEFAULT);
                                y_binding = bind_property ("control_y", s, "y2", BindingFlags.DEFAULT);
                                control_x = x;
                                control_y = y;
                                return false;
                            }
                            // Intentional fall-through
                        case SegmentType.MOVE:
                        case SegmentType.LINE:
                            if ((x - s.x).abs () <= 6 / zoom && (y - s.y).abs () <= 6 / zoom) {
                                x_binding = bind_property ("control_x", s, "x", BindingFlags.DEFAULT);
                                y_binding = bind_property ("control_y", s, "y", BindingFlags.DEFAULT);
                                control_x = x;
                                control_y = y;
                                return false;
                            }
                            break;
                    }
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
            control_x = scale_x (event.x);
            control_y = scale_y (event.y);
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
            x_binding.unbind ();
            y_binding.unbind ();
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
            foreach (Segment _segment in _path.segments) {
                _segment.do_command (cr);
                cr.stroke_preserve ();
                // Check alpha of clicked pixel
                if (data [y * width * 4 + x * 4 + 3] > 0) {
                    path = _path;
                    segment = _segment;
                    return true;
                }
            }
            cr.new_path ();
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

            switch (segment.segment_type) {
                case LINE:
                    line_mode.active = true;
                    break;
                case CURVE:
                    curve_mode.active = true;
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
