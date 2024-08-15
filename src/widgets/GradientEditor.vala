public class GradientEditor : Gtk.Box {
    private Pattern _pattern;
    public Pattern pattern {
        get {
            return _pattern;
        }
        set {
            _pattern = value;
            _pattern.notify.connect (() => { request_draw (); });
            _pattern.items_changed.connect ((index, removed, added) => {
                for (var i = 0; i < added; i++) {
                    var stop = (Stop) pattern.get_item (index + i);
                    stop.notify.connect (() => { request_draw (); });
                }
                request_draw ();
            });
            for (var i = 0; i < _pattern.get_n_items(); i++) {
                var stop = (Stop) _pattern.get_item (i);
                stop.notify.connect (() => { request_draw (); });
            }
        }
    }

    private double base_offset;

    private Gtk.DrawingArea pattern_view;
    private Gtk.DrawingArea stop_view;

    public double offset { get; set; }

    private Binding stop_binding;
    private Stop bound_stop;

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        sensitive = true;

        pattern_view = new Gtk.DrawingArea () {
            hexpand = true,
            vexpand = true,
            content_height = 30,
        };

        stop_view = new Gtk.DrawingArea () {
            hexpand = true,
            content_height = 40,
        };

        pattern_view.set_draw_func ((d, cr, w, h) => {
            pattern.apply_custom (cr, {15, h / 2}, {w - 15, h / 2}, PatternType.LINEAR);
            cr.paint ();
            if (!sensitive) {
                cr.set_source_rgba(0.8, 0.8, 0.8, 0.2);
                cr.paint();
            }
        });

        stop_view.set_draw_func((d, cr, w, h) => {
            for (int i = 0; i < pattern.get_n_items(); i++) {
                Stop s = (Stop) pattern.get_item (i);
                var cx = 15 + (w - 30) * s.offset;
                cr.move_to (cx, h - 35);
                cr.line_to (cx + 10, h - 25);
                cr.line_to (cx + 10, h - 5);
                cr.line_to (cx - 10, h - 5);
                cr.line_to (cx - 10, h - 25);
                cr.close_path ();

                var darkness = 0.4;
                if (!sensitive) {
                    darkness += 0.2;
                }

                cr.set_source_rgb (darkness, darkness, darkness);
                cr.fill ();
                cr.rectangle (cx - 8, h - 23, 16, 16);
                cr.set_source_rgba (s.rgba.red, s.rgba.green, s.rgba.blue, s.rgba.alpha);
                if (!sensitive) {
                    cr.fill_preserve();
                    cr.set_source_rgba(0.8, 0.8, 0.8, 0.2);
                }

                cr.fill ();
            }
        });

        var stop_click_controller = new Gtk.GestureClick ();
        stop_view.add_controller (stop_click_controller);
        stop_click_controller.pressed.connect ((n, x, y) => {
            if (sensitive && n == 2) {
                for (int i = 0; i < pattern.get_n_items(); i++) {
                    Stop stop = (Stop) pattern.get_item (i);
                    var cx = 15 + (pattern_view.get_width () - 30) * stop.offset;
                    if (cx - 10 < x && x < cx + 10) {
                        var dialog = new Gtk.ColorDialog () {
                            title = _("Stop Color"),
                            with_alpha = true,
                        };
                        stop.begin ("rgba");
                        dialog.choose_rgba.begin (root as Gtk.Window, stop.rgba, null, (obj, res) => {
                            try {
                                var color = dialog.choose_rgba.end (res);
                                if (color != null) {
                                    stop.begin ("rgba");
                                    stop.rgba = color;
                                    stop.finish ("rgba");
                                }
                            } catch (GLib.Error e) {
                                // TODO: Display error
                            }
                        });
                    }
                }
            }
        });

        var pattern_click_controller = new Gtk.GestureClick ();
        pattern_view.add_controller(pattern_click_controller);
        pattern_click_controller.pressed.connect ((n, x, y) => {
            if (sensitive) {
                var offset = (x - 15) / (pattern_view.get_width () - 30);
                pattern.add_stop (new Stop (offset, pattern.rgba));
            }
        });

        var drag_controller = new Gtk.GestureDrag ();
        stop_view.add_controller (drag_controller);
        drag_controller.drag_begin.connect ((x, y) => {
            if (sensitive) {
                for (int i = 0; i < pattern.get_n_items(); i++) {
                    Stop stop = (Stop) pattern.get_item (i);
                    var cx = 15 + (pattern_view.get_width () - 30) * stop.offset;
                    if (cx - 10 < x && x < cx + 10) {
                        stop.begin ("offset");
                        bound_stop = stop;
                        stop_binding = bind_property ("offset", stop, "offset");
                        base_offset = x - 15;
                        return;
                    }
                }
            }
        });

        drag_controller.drag_update.connect ((offset_x, offset_y) => {
            offset = double.min (1, double.max (0, (offset_x + base_offset) / (pattern_view.get_width () - 30)));
        });

        drag_controller.drag_end.connect ((offset_x, offset_y) => {
            offset = double.min (1, double.max (0, (offset_x + base_offset) / (pattern_view.get_width () - 30)));
            if (stop_binding != null) {
                stop_binding.unbind ();
                stop_binding = null;
                bound_stop.finish ("offset");
            }
        });

        append (new Gtk.Frame (null) { child = pattern_view, });
        append (stop_view);
    }

    private void request_draw () {
        pattern_view.queue_draw();
        stop_view.queue_draw();
    }
}
