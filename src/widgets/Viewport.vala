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
                selected_path.draw (cr, 1 / zoom, {0, 0, 0, 0}, {1, 0, 0, 1});
                
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
                            cr.arc (s.x1, s.y1, 4 / zoom, 0, 3.14159265 * 2);
                            cr.new_sub_path ();
                            cr.arc (s.x2, s.y2, 4 / zoom, 0, 3.14159265 * 2);
                            cr.new_sub_path ();
                            // Intentional fall-through
                        case SegmentType.MOVE:
                        case SegmentType.LINE:
                            cr.arc (s.x, s.y, 4 / zoom, 0, 3.14159265 * 2);
                            cr.set_source_rgba (1, 0, 0, 0.9);
                            cr.fill ();
                            last_x = s.x;
                            last_y = s.y;
                        case SegmentType.CLOSE:
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
            var x = scale_x (event.x);
            var y = scale_y (event.y);
            // Check for clicking on a control handle
            if (selected_path != null) {
                foreach (Segment s in selected_path.segments) {
                    switch (s.segment_type) {
                        case SegmentType.CURVE:
                            if ((x - s.x1).abs () <= 4 / zoom && (y - s.y1).abs () <= 4 / zoom) {
                                x_binding = bind_property ("control_x", s, "x1", BindingFlags.DEFAULT);
                                y_binding = bind_property ("control_y", s, "y1", BindingFlags.DEFAULT);
                                control_x = x;
                                control_y = y;
                                return false;
                            }
                            if ((x - s.x2).abs () <= 4 / zoom && (y - s.y2).abs () <= 4 / zoom) {
                                x_binding = bind_property ("control_x", s, "x2", BindingFlags.DEFAULT);
                                y_binding = bind_property ("control_y", s, "y2", BindingFlags.DEFAULT);
                                control_x = x;
                                control_y = y;
                                return false;
                            }
                            // Intentional fall-through
                        case SegmentType.MOVE:
                        case SegmentType.LINE:
                            if ((x - s.x).abs () <= 4 / zoom && (y - s.y).abs () <= 4 / zoom) {
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
            // Check for clicking on a segment
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
}
