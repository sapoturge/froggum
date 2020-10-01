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
    
    private Tutorial tutorial;

    public Point control_point { get; set; }

    private Binding point_binding;

    public Image image {
        get {
            return _image;
        }
        set {
            _image = value;
            _image.update.connect (() => {
                queue_draw ();
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
                            cr.arc (s.p1.x, s.p1.y, 6 / zoom, 0, Math.PI * 2);
                            cr.new_sub_path ();
                            cr.arc (s.p2.x, s.p2.y, 6 / zoom, 0, Math.PI * 2);
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

                if (selected_path.fill.pattern_type == PatternType.LINEAR ||
                    selected_path.fill.pattern_type == PatternType.RADIAL) {
                    cr.move_to (selected_path.fill.start.x, selected_path.fill.start.y);
                    cr.line_to (selected_path.fill.end.x, selected_path.fill.end.y);
                    cr.set_source_rgba (0, 1, 0, 0.9);
                    cr.stroke ();

                    cr.arc (selected_path.fill.start.x, selected_path.fill.start.y, 6 / zoom, 0, Math.PI * 2);
                    cr.new_sub_path ();
                    cr.arc (selected_path.fill.end.x, selected_path.fill.end.y, 6 / zoom, 0, Math.PI * 2);
                 
                    for (int i = 0; i < selected_path.fill.get_n_items (); i++) {
                        var stop = (Stop) selected_path.fill.get_item (i);
                        cr.new_sub_path ();
                        cr.arc (stop.display.x, stop.display.y, 6 / zoom, 0, Math.PI * 2);
                    }

                    cr.fill ();

                    for (int i = 0; i < selected_path.fill.get_n_items (); i++) {
                        var stop = (Stop) selected_path.fill.get_item (i);
                        cr.new_sub_path ();
                        cr.arc (stop.display.x, stop.display.y, 4 / zoom, 0, Math.PI * 2);
                        cr.set_source_rgba (stop.rgba.red, stop.rgba.green, stop.rgba.blue, stop.rgba.alpha);
                        cr.fill ();
                    }
                }

                if (selected_path.stroke.pattern_type == PatternType.LINEAR ||
                    selected_path.stroke.pattern_type == PatternType.RADIAL) {
                    cr.move_to (selected_path.stroke.start.x, selected_path.stroke.start.y);
                    cr.line_to (selected_path.stroke.end.x, selected_path.stroke.end.y);
                    cr.set_source_rgba (0, 1, 0, 0.9);
                    cr.stroke ();

                    cr.arc (selected_path.stroke.start.x, selected_path.stroke.start.y, 6 / zoom, 0, Math.PI * 2);
                    cr.new_sub_path ();
                    cr.arc (selected_path.stroke.end.x, selected_path.stroke.end.y, 6 / zoom, 0, Math.PI * 2);

                    for (int i = 0; i < selected_path.stroke.get_n_items (); i++) {
                        var stop = (Stop) selected_path.stroke.get_item (i);
                        cr.new_sub_path ();
                        cr.arc (stop.display.x, stop.display.y, 6 / zoom, 0, Math.PI * 2);
                    }

                    cr.fill ();

                    for (int i = 0; i < selected_path.stroke.get_n_items (); i++) {
                        var stop = (Stop) selected_path.stroke.get_item (i);
                        cr.new_sub_path ();
                        cr.arc (stop.display.x, stop.display.y, 4 / zoom, 0, Math.PI * 2);
                        cr.set_source_rgba (stop.rgba.red, stop.rgba.green, stop.rgba.blue, stop.rgba.alpha);
                        cr.fill ();
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
            
            if (FroggumApplication.settings.get_boolean ("show-tutorial")) {
                FroggumApplication.settings.set_boolean ("show-tutorial", false);
                tutorial = new Tutorial ();
                tutorial.relative_to = this;
                tutorial.pointing_to = { (int) (width / 2), (int) (height / 2) };
                print ("Showing tutorial!\n");
                tutorial.popup ();
            }
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
                    if (tutorial != null && tutorial.step == CLICK) {
                        tutorial.next_step ();
                    }
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
                        point_binding = bind_property ("control-point", s, "end");
                        control_point = {x, y};
                        return false;
                    }
                    switch (s.segment_type) {
                        case SegmentType.CURVE:
                            if ((x - s.p1.x).abs () <= 6 / zoom && (y - s.p1.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control-point", s, "p1");
                                control_point = {x, y};
                                return false;
                            }
                            if ((x - s.p2.x).abs () <= 6 / zoom && (y - s.p2.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control-point", s, "p2");
                                control_point = {x, y};
                                return false;
                            }
                            break;
                        case SegmentType.ARC:
                            if ((x - s.controller.x).abs () <= 6 / zoom && (y - s.controller.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control-point", s, "controller");
                                control_point = {x, y};
                                return false;
                            }
                            if ((x - s.topleft.x).abs () <= 6 / zoom && (y - s.topleft.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control-point", s, "topleft");
                                control_point = {x, y};
                                return false;
                            }
                            if ((x - s.topright.x).abs () <= 6 / zoom && (y - s.topright.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control-point", s, "topright");
                                control_point = {x, y};
                                return false;
                            }
                            if ((x - s.bottomleft.x).abs () <= 6 / zoom && (y - s.bottomleft.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control-point", s, "bottomleft");
                                control_point = {x, y};
                                return false;
                            }
                            if ((x - s.bottomright.x).abs () <= 6 / zoom && (y - s.bottomright.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control-point", s, "bottomright");
                                control_point = {x, y};
                                return false;
                            }
                            if ((x - s.center.x).abs () <= 6 / zoom && (y - s.center.y).abs () <= 6 / zoom) {
                                point_binding = bind_property ("control-point", s, "center");
                                control_point = {x, y};
                                return false;
                            }
                            break;
                    }
                    s = s.next;
                }

                if (selected_path.fill.pattern_type == LINEAR || selected_path.fill.pattern_type == RADIAL) {
                    for (var i = 0; i < selected_path.fill.get_n_items (); i++) {
                        var stop = (Stop) selected_path.fill.get_item (i);
                        if ((x - stop.display.x).abs () <= 6 / zoom && (y - stop.display.y).abs () <= 6 / zoom) {
                            point_binding = bind_property ("control-point", stop, "display");
                            control_point = {x, y};
                            return false;
                        }
                    }
                    if ((x - selected_path.fill.start.x).abs () <= 6 / zoom && (y - selected_path.fill.start.y).abs () <= 6 / zoom) {
                        point_binding = bind_property ("control-point", selected_path.fill, "start");
                        control_point = {x, y};
                        return false;
                    }
                    if ((x - selected_path.fill.end.x).abs () <= 6 / zoom && (y - selected_path.fill.end.y).abs () <= 6 / zoom) {
                        point_binding = bind_property ("control-point", selected_path.fill, "end");
                        control_point = {x, y};
                        return false;
                    }
                }

                if (selected_path.stroke.pattern_type == LINEAR || selected_path.stroke.pattern_type == RADIAL) {
                    for (var i = 0; i < selected_path.stroke.get_n_items (); i++) {
                        var stop = (Stop) selected_path.stroke.get_item (i);
                        if ((x - stop.display.x).abs () <= 6 / zoom && (y - stop.display.y).abs () <= 6 / zoom) {
                            point_binding = bind_property ("control-point", stop, "display");
                            control_point = {x, y};
                            return false;
                        }
                    }
                    if ((x - selected_path.stroke.start.x).abs () <= 6 / zoom && (y - selected_path.stroke.start.y).abs () <= 6 / zoom) {
                        point_binding = bind_property ("control-point", selected_path.stroke, "start");
                        control_point = {x, y};
                        return false;
                    }
                    if ((x - selected_path.stroke.end.x).abs () <= 6 / zoom && (y - selected_path.stroke.end.y).abs () <= 6 / zoom) {
                        point_binding = bind_property ("control-point", selected_path.stroke, "end");
                        control_point = {x, y};
                        return false;
                    }
                }
            }
            // Check for clicking on a path (not control handle)
            if (clicked && path == selected_path) {
                selected_path.start_dragging ({x, y});
                point_binding = bind_property ("control-point", selected_path, "reference");
                control_point = {x, y};
                return false;
            }
            // Assume dragging
            scrolling = true;
            base_x = (int) event.x - scroll_x;
            base_y = (int) event.y - scroll_y;
            return false;
        });

        motion_notify_event.connect ((event) => {
            // Drag control handle (only changes if actually dragging something.)
            if (point_binding != null) {
                var new_x = scale_x (event.x);
                var new_y = scale_y (event.y);
                if ((new_x * 2 - Math.round (new_x * 2)).abs () < 6 / zoom) {
                    new_x = Math.round (new_x * 2) / 2;
                }
                if ((new_y * 2 - Math.round (new_y * 2)).abs () < 6 / zoom) {
                    new_y = Math.round (new_y * 2) / 2;
                }
                control_point = {new_x, new_y};
            }
            // Drag entire segment?
            // Scroll
            if (scrolling) {
                scroll_x = (int) event.x - base_x;
                scroll_y = (int) event.y - base_y;
                queue_draw ();
            }
            return false;
        });

        button_release_event.connect ((event) => {
            // Stop scrolling, dragging, etc.
            if (point_binding != null) {
                point_binding.unbind ();
                point_binding = null;
            }
            scrolling = false;
            return false;
        });

        scroll_event.connect ((event) => {
            if (event.direction == Gdk.ScrollDirection.UP) {
                if (tutorial != null && tutorial.step == SCROLL) {
                    tutorial.next_step ();
                }
                zoom *= 2;
                scroll_x *= 2;
                scroll_y *= 2;
            } else if (event.direction == Gdk.ScrollDirection.DOWN && zoom > 1) {
                zoom /= 2;
                scroll_x /= 2;
                scroll_y /= 2;
            }
            queue_draw ();
            return false;
        });
    }

    public bool get_border (out Gtk.Border border) {
        border = {0, 0, 0, 0};
        return true;
    }

    private bool clicked_path (int x, int y, out Path? path, out Segment? segment) {
        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
        unowned uchar[] data = surface.get_data ();
        var cr = new Cairo.Context (surface);
        cr.translate (width / 2, height / 2);
        cr.translate (scroll_x, scroll_y);
        cr.scale (zoom, zoom);
        cr.set_line_width (6 / zoom);
        cr.set_source_rgba (1, 1, 1, 1);
        var paths = image.get_paths ();
        for (int i = paths.length - 1; i >= 0; i--) {
            var _path = paths[i];
            if (_path.visible || _path == selected_path) {
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
        var menu = new Gtk.Popover (this);
        var menu_layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        var delete_path = new Gtk.Button ();
        delete_path.label = "Delete Path";
        delete_path.clicked.connect (() => {
            image.delete_path ();
            menu.popdown ();
        });
        menu_layout.pack_start (delete_path, false, false, 0);

        if (segment != null) {
            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            menu_layout.pack_start (separator, false, false, 0);

            var delete_segment = new Gtk.Button ();
            delete_segment.label = _("Delete Segment");
            delete_segment.clicked.connect (() => {
                // TODO: Delete segment.
                menu.popdown ();
            });
            menu_layout.pack_start (delete_segment, false, false, 0);

            var split_segment = new Gtk.Button ();
            split_segment.label = _("Split Segment");
            split_segment.clicked.connect (() => {
                 selected_path.split_segment (segment);
                 menu.popdown ();
            });
            menu_layout.pack_start (split_segment, false, false, 0);

            if (segment.segment_type == ARC) {
                var flip_arc = new Gtk.Button ();
                flip_arc.label = _("Flip Arc");
                flip_arc.clicked.connect (() => {
                    segment.reverse = !segment.reverse;
                    menu.popdown ();
                });
                menu_layout.pack_start (flip_arc, false, false, 0);
            }

            var separator2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            menu_layout.pack_start (separator2, false, false, 0);

            var switch_mode = new Gtk.Label (_("Change segment to:"));
            menu_layout.pack_start (switch_mode, false, false, 0);

            var line_mode = new Gtk.RadioButton.with_label (null, _("Line"));
            line_mode.toggled.connect (() => {
                if (line_mode.get_active ()) {
                    segment.segment_type = LINE;
                    menu.popdown ();
                }
            });
            menu_layout.pack_start (line_mode, false, false, 0);

            var curve_mode = new Gtk.RadioButton.with_label_from_widget (line_mode, _("Curve"));
            curve_mode.toggled.connect (() => {
                if (curve_mode.get_active ()) {
                    segment.segment_type = CURVE;
                    menu.popdown ();
                }
            });
            menu_layout.pack_start (curve_mode, false, false, 0);

            var arc_mode = new Gtk.RadioButton.with_label_from_widget (line_mode, _("Arc"));
            arc_mode.toggled.connect (() => {
                if (arc_mode.get_active ()) {
                    segment.segment_type = ARC;
                    menu.popdown ();
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

        menu.add (menu_layout);

        menu.pointing_to = {(int) event.x - 5, (int) event.y - 5, 10, 10};

        menu.popup ();
    }
}
