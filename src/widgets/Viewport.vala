public class Viewport : Gtk.DrawingArea, Gtk.Scrollable {
    private int _scroll_x;
    private int _scroll_y;
    private int base_x;
    private int base_y;
    private double _zoom = 1;
    private int width = 0;
    private int height = 0;

    private bool scrolling = false;

    private Element? selected_path;

    private Gdk.RGBA background;

    private Image _image;
    private Gtk.Adjustment horizontal;
    private Gtk.Adjustment vertical;
    
    private Tutorial tutorial;

    public Point control_point { get; set; }

    private Binding point_binding;
    
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
                selected_path.draw_controls (cr, zoom);
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
                tutorial.finish.connect (() => { tutorial = null; });
                tutorial.relative_to = this;
                position_tutorial ();
                tutorial.popup ();
            }
        });

        button_press_event.connect ((event) => {
            Element path = null;
            Segment segment = null;
            var clicked = clicked_path ((int) event.x, (int) event.y, out path, out segment);
            var x = scale_x (event.x);
            var y = scale_y (event.y);
            control_point = {x, y};
            // Check for right-clicking on a segment
            if (path != null && event.button == 3) {
                if (clicked) {
                    path.select (true);
                }
                show_context_menu (path, segment, event);
                return false;
            }
            // Check for double-clicking on a path
            if (event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) {
                if (clicked) {
                    if (tutorial != null && tutorial.step == CLICK) {
                        tutorial.next_step ();
                    }
                    path.select (true);
                } else if (selected_path != null) {
                    selected_path.select (false);
                }
                return false;
            }
            // Check for clicking on a control handle
            if (selected_path != null) {
                Undoable obj;
                string prop;
                selected_path.check_controls (x, y, 6 / zoom, out obj, out prop);
                if (obj != null) {
                    bind_point (obj, prop);
                    return false;
                }
            }
            // Check for clicking on a path (not control handle)
            if (clicked && path == selected_path) {
                bind_point (selected_path, "reference");
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
                position_tutorial ();
                queue_draw ();
            }
            return false;
        });

        button_release_event.connect ((event) => {
            // Stop scrolling, dragging, etc.
            if (point_binding != null) {
                unbind_point ();
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
            position_tutorial ();
            queue_draw ();
            return false;
        });
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
        obj.begin (name, control_point);
        point_binding = bind_property ("control-point", obj, name);
    }

    private void unbind_point () {
        bound_obj.finish (bound_prop);
        point_binding.unbind ();
        point_binding = null;
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

    private bool clicked_path (int x, int y, out Element? path, out Segment? segment) {
        double real_x = scale_x (x);
        double real_y = scale_y (y);
        return clicked_subpath (real_x, real_y, null, out path, out segment);
    }

    private bool clicked_subpath (double x, double y, Gtk.TreeIter? root, out Element? path, out Segment? segment) {
        Gtk.TreeIter iter;
        if (image.iter_children (out iter, root)) {
            do {
                var element = image.get_element (iter);
                if (element.visible) {
                    if (element.clicked (x, y, 6 / zoom, out segment)) {
                        path = element;
                        return true;
                    } else if (element is Group) {
                        // TODO: Apply transformation
                        if (clicked_subpath (x, y, iter, out path, out segment)) {
                            return true;
                        }
                    }
                }
            } while (image.iter_next (ref iter));
        }
        path = null;
        segment = null;
        return false;
    }
        
    private void show_context_menu (Element element, Segment? segment, Gdk.EventButton event) {
        var menu = new Gtk.Popover (this);
        var menu_layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        var elem_options = element.options (); // Using the full name "element_options" causes a name collision with "Element.options"

        Gee.List<ContextOption>? seg_options;

        if (segment != null) {
            seg_options = segment.options ();
        } else {
            seg_options = null;
        }

        var options = new Gee.ArrayList<ContextOption> ();

        bool needs_separator = false;
        bool will_need_separator = false;

        ContextOptionType[] op_types = {ACTION, OPTIONS, TOGGLE};

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
        }

        foreach (ContextOption option in options) {
            switch (option.option_type) {
            case SEPARATOR:
                var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
                menu_layout.pack_start (separator, false, false, 0);
                break;
            case ACTION:
                var button = new Gtk.Button ();
                button.label = option.label;
                button.clicked.connect (() => {
                    option.activate ();
                    menu.popdown ();
                });
                menu_layout.pack_start (button, false, false, 0);
                break;
            case TOGGLE:
                var button = new Gtk.CheckButton.with_label (option.label);
                bool value = false;
                option.target.get(option.prop, &value);
                button.set_active (value);
                button.toggled.connect (() => {
                    bool val = false;
                    option.target.get(option.prop, &val);
                    option.target.begin (option.prop, val);
                    option.target.set(option.prop, !val);
                    option.target.finish (option.prop);
                    menu.popdown ();
                });
                menu_layout.pack_start (button, false, false, 0);
                break;
            case OPTIONS:
                var caption = new Gtk.Label (option.label);
                menu_layout.pack_start (caption, false, false, 0);
                int value = 0;
                option.target.get(option.prop, &value);
                Gtk.RadioButton first_button = null;

                foreach (Gee.Map.Entry<string, int> variant in option.option_values) {
                    Gtk.RadioButton button;
                    if (first_button == null) {
                        button = new Gtk.RadioButton.with_label (null, variant.key);
                        first_button = button;
                    } else {
                        button = new Gtk.RadioButton.with_label_from_widget(first_button, variant.key);
                    }

                    button.toggled.connect (() => {
                        if (button.get_active ()) {
                            Value previous;
                            option.target.get (option.prop, out previous);
                            option.target.begin (option.prop, previous);
                            option.target.set(option.prop, variant.value);
                            option.target.finish (option.prop);
                            menu.popdown ();
                        }
                    });
                    menu_layout.pack_start (button, false, false, 0);
                    if (value == variant.value) {
                        button.active = true;
                    }
                }
                break;
            }
        }

        menu_layout.show_all ();

        menu.add (menu_layout);

        menu.pointing_to = {(int) event.x - 5, (int) event.y - 5, 10, 10};

        menu.popup ();
    }
}
