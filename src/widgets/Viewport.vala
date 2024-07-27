public class Viewport : Gtk.DrawingArea, Gtk.Scrollable {
    private double _scroll_x;
    private double _scroll_y;
    private double base_x;
    private double base_y;
    private double _zoom = 1;
    private double base_zoom;
    private int width = 0;
    private int height = 0;
    private Point base_point;

    private bool scrolling = false;

    private Gdk.RGBA background;

    private Image _image;
    private Gtk.Adjustment horizontal;
    private Gtk.Adjustment vertical;
    
    private Tutorial tutorial;

    public Point control_point { get; set; }
    public Point cursor { get; private set; }

    private Binding point_binding;
    public Handle? current_handle { get; private set; }
    
    private Undoable bound_obj;
    private string bound_prop;

    public Image image {
        get {
            return _image;
        }
        set {
            _image = value;
            _image.update.connect (() => {
                queue_draw ();
            });
            image.path_selected.connect (() => {
                current_handle = null;
            });
            scroll_x = -_image.width / 2;
            scroll_y = -_image.height / 2;
        }
    }

    private double scroll_x {
        get {
            return _scroll_x;
        }
        set {
            _scroll_x = value;
            horizontal.value = -double.min (scroll_x + width / 2, 0);
        }
    }

    private double scroll_y {
        get {
            return _scroll_y;
        }
        set {
            _scroll_y = value;
            vertical.value = double.max (scroll_y + height / 2, 0);
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
    
    private double unscale_x (double x) {
        return x * zoom + scroll_x + width / 2;
    }

    private double scale_y (double y) {
        return (y - height / 2 - scroll_y) / zoom;
    }
    
    private double unscale_y (double y) {
        return y * zoom + scroll_y + height / 2;
    }

    construct {
        background = {0.7f, 0.7f, 0.7f, 1.0f};

        set_size_request (320, 320);

        set_draw_func ((d, cr, w, h) => {
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
            image.draw_selected_child (cr, zoom);
            if (current_handle != null) {
                Point center = current_handle.point;
                cr.arc (center.x, center.y, 7/zoom, 0, Math.PI*2);
                cr.set_line_width (2 / zoom);
                cr.set_source_rgb (0.95, 0.85, 0.15);
                cr.stroke ();
            }

            cr.restore();
        });

        var double_click_controller = new Gtk.GestureClick ();
        add_controller (double_click_controller);
        double_click_controller.pressed.connect ((n, x, y) => {
            if (n == 2) {
                Element path;
                Segment segment;
                Handle handle;
                if (image.clicked_child (scale_x (x), scale_y (y), 6 / zoom, out path, out segment, out handle)) {
                    if (tutorial != null && tutorial.step == CLICK) {
                        tutorial.next_step ();
                    }

                    path.select (true);
                    current_handle = handle;
                } else {
                    image.deselect ();
                    current_handle = null;
                }
            }
        });

        var right_click_controller = new Gtk.GestureClick ();
        right_click_controller.set_button (3);
        add_controller (right_click_controller);
        right_click_controller.pressed.connect ((n, x, y) => {
            Element path;
            Segment segment;
            Handle handle;
            if (image.clicked_child (scale_x (x), scale_y (y), 6 / zoom, out path, out segment, out handle)) {
                path.select (true);
                current_handle = handle;
                show_context_menu (path, segment, handle, x, y);
            }
        });

        var motion_controller = new Gtk.EventControllerMotion ();
        add_controller (motion_controller);
        motion_controller.motion.connect ((x, y) => {
            var sx = scale_x(x);
            var sy = scale_y(y);
            cursor = {sx, sy};
        });

        var drag_controller = new Gtk.GestureDrag ();
        add_controller (drag_controller);
        drag_controller.drag_begin.connect ((x, y) => {
            var sx = scale_x (x);
            var sy = scale_y (y);
            control_point = {sx, sy};

            // Check for clicking on a control handle
            if (image.has_selected ()) {
                Handle obj;
                if (image.clicked_handle (sx, sy, 6 / zoom, out obj)) {
                    current_handle = obj;
                    bind_point (obj, "point");
                    return;
                }
            }

            // Assume dragging
            scrolling = true;
            base_x = scroll_x;
            base_y = scroll_y;
        });

        drag_controller.drag_update.connect ((x, y) => {
            // Drag control handle (only changes if actually dragging something.)
            if (point_binding != null) {
                var new_x = x / zoom + base_point.x;
                var new_y = y / zoom + base_point.y;

                // Snap to grid if within tolerance
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
                scroll_x = x + base_x;
                scroll_y = y + base_y;
                position_tutorial ();
                queue_draw ();
            }
        });

        drag_controller.drag_end.connect ((event) => {
            // Stop scrolling, dragging, etc.
            if (point_binding != null) {
                unbind_point ();
            }

            scrolling = false;
        });

        var scroll_controller = new Gtk.EventControllerScroll (Gtk.EventControllerScrollFlags.BOTH_AXES);
        add_controller (scroll_controller);
        scroll_controller.scroll.connect ((dx, dy) => {
            // Differentiates between mice and touchpads: mice zoom by scrolling, touchpads don't
            if (dx == 0) {
                update_zoom (Math.pow (2, -dy) * zoom);
            }
        });

        var zoom_controller = new Gtk.GestureZoom ();
        add_controller (zoom_controller);
        zoom_controller.begin.connect (() => {
            base_zoom = zoom;
        });
        zoom_controller.scale_changed.connect ((scale) => {
            update_zoom (scale * base_zoom);
        });

        resize.connect ((width, height) => {
            this.width = width;
            this.height = height;
            horizontal.page_size = width;
            vertical.page_size = height;

            // Recalculate values.
            scroll_x = scroll_x;
            scroll_y = scroll_y;
        });

        if (FroggumApplication.settings.get_boolean ("show-tutorial")) {
            FroggumApplication.settings.set_boolean ("show-tutorial", false);
            tutorial = new Tutorial ();
            tutorial.finish.connect (() => { tutorial = null; });
            tutorial.set_parent (this);
            position_tutorial ();
            tutorial.popup ();
        }
    }

    private void update_zoom (double new_zoom) {
        new_zoom = double.max (new_zoom, 1);

        if (new_zoom > 1 && tutorial != null && tutorial.step == SCROLL) {
            tutorial.next_step ();
        }

        scroll_x *= new_zoom;
        scroll_x /= zoom;
        scroll_y *= new_zoom;
        scroll_y /= zoom;
        zoom = new_zoom;

        position_tutorial ();
        queue_draw ();
    }

    public bool get_border (out Gtk.Border border) {
        border = {0, 0, 0, 0};
        return true;
    }

    private void bind_point (Undoable obj, string name) {
        if (tutorial != null && tutorial.step == DRAG) {
            tutorial.next_step ();
        }

        bound_obj = obj;
        bound_prop = name;
        obj.begin (name);
        point_binding = bind_property ("control-point", obj, name);
        base_point = control_point;
        queue_draw ();
    }

    private void unbind_point () {
        bound_obj.finish (bound_prop);
        point_binding.unbind ();
        point_binding = null;
        queue_draw ();
    }
    
    private void position_tutorial () {
        if (tutorial != null) {
            var x = unscale_x (image.width / 2);
            var y = unscale_y (0);

            if (y < 0) {
                y = 0;
                tutorial.position = BOTTOM;
            } else if (y > height) {
                y = height;
            }

            if (x < 0) {
                x = 0;
            } else if (x > width) {
                x = width;
            }

            tutorial.pointing_to = { (int) x, (int) y };
        }
    }

    private void show_context_menu (Element element, Segment? segment, Handle? handle, double x, double y) {
        var menu = new Gtk.Popover ();
        var menu_layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        var elem_options = element.options (); // Using the full name "element_options" causes a name collision with "Element.options"

        Gee.List<ContextOption>? seg_options;

        if (segment != null) {
            seg_options = segment.options ();
        } else {
            seg_options = null;
        }

        Gee.List<ContextOption>? hand_options;

        if (handle != null) {
            hand_options = handle.options;
        } else {
            hand_options = null;
        }

        var options = new Gee.ArrayList<ContextOption> ();

        bool needs_separator = false;
        bool will_need_separator = false;

        // Order that options appear. This should include all option types except separator
        ContextOptionType[] op_types = {COLOR, ACTION, OPTIONS, TOGGLE, DELETER};

        foreach (int op_type in op_types) {
            foreach (ContextOption op in elem_options) {
                if (op.option_type == op_type) {
                    if (needs_separator) {
                        needs_separator = false;
                        options.add (new ContextOption.separator ());
                    }

                    options.add (op);
                    will_need_separator = true;
                }
            }

            needs_separator = will_need_separator;

            if (seg_options != null) {
                foreach (ContextOption op in seg_options) {
                    if (op.option_type == op_type) {
                        if (needs_separator) {
                            needs_separator = false;
                            options.add (new ContextOption.separator ());
                        }

                        options.add (op);
                        will_need_separator = true;
                    }
                }

                needs_separator = will_need_separator;
            }

            if (hand_options != null) {
                foreach (ContextOption op in hand_options) {
                    if (op.option_type == op_type) {
                        if (needs_separator) {
                            needs_separator = false;
                            options.add (new ContextOption.separator ());
                        }

                        options.add (op);
                        will_need_separator = true;
                    }
                }

                needs_separator = will_need_separator;
            }
        }

        foreach (ContextOption option in options) {
            switch (option.option_type) {
            case SEPARATOR:
                var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
                menu_layout.append (separator);
                break;
            case ACTION:
                var button = new Gtk.Button ();
                button.label = option.label;
                button.clicked.connect (() => {
                    option.activate ();
                    menu.popdown ();
                });
                menu_layout.append (button);
                break;
            case DELETER:
                var button = new Gtk.Button ();
                button.add_css_class ("destructive-action");
                button.label = option.label;
                button.clicked.connect (() => {
                    option.activate ();
                    current_handle = null;
                    menu.popdown ();
                });
                menu_layout.append (button);
                break;
            case TOGGLE:
                var button = new Gtk.CheckButton.with_label (option.label);
                bool value = false;
                option.target.get(option.prop, &value);
                button.set_active (value);
                button.toggled.connect (() => {
                    bool val = false;
                    option.target.get(option.prop, &val);
                    option.target.begin (option.prop);
                    option.target.set(option.prop, !val);
                    option.target.finish (option.prop);
                    menu.popdown ();
                });
                menu_layout.append (button);
                break;
            case COLOR:
                Gdk.RGBA? rgba = Gdk.RGBA ();
                option.target.get (option.prop, &rgba);
                var dialog = new Gtk.ColorDialog () {
                    with_alpha = true,
                };
                var button = new Gtk.ColorDialogButton (dialog) {
                    rgba = rgba,
                };
                button.notify["rgba"].connect (() => {
                    option.target.begin (option.prop);
                    option.target.set (option.prop, button.get_rgba ());
                    option.target.finish (option.prop);
                });
                var label = new Gtk.Label (option.label) {
                    hexpand = true,
                };
                var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                row.append (label);
                row.append (button);
                menu_layout.append (row);
                break;
            case OPTIONS:
                var caption = new Gtk.Label (option.label);
                menu_layout.append (caption);
                int value = 0;
                option.target.get(option.prop, &value);
                Gtk.ToggleButton first_button = null;

                foreach (Gee.Map.Entry<string, int> variant in option.option_values) {
                    Gtk.ToggleButton button = new Gtk.ToggleButton.with_label (variant.key);
                    if (first_button == null) {
                        first_button = button;
                    } else {
                        button.group = first_button;
                    }

                    button.toggled.connect (() => {
                        if (button.get_active ()) {
                            option.target.begin (option.prop);
                            option.target.set(option.prop, variant.value);
                            option.target.finish (option.prop);
                            menu.popdown ();
                        }
                    });
                    menu_layout.append (button);
                    if (value == variant.value) {
                        button.active = true;
                    }
                }
                break;
            default:
                stderr.printf ("Unknown option type\n");
                break;
            }
        }

        menu.child = menu_layout;
        menu.set_parent (this);
        menu.pointing_to = {(int) x - 5, (int) y - 5, 10, 10};

        menu.popup ();
    }
}
