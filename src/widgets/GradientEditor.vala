public class GradientEditor : Gtk.DrawingArea {
    private Pattern _pattern;
    public Pattern pattern {
        get {
            return _pattern;
        }
        set {
            _pattern = value;
            _pattern.items_changed.connect ((index, removed, added) => {
                for (var i = 0; i < added; i++) {
                    var stop = (Stop) pattern.get_item (index + i);
                    stop.notify.connect (() => { queue_draw (); });
                }
                queue_draw ();
            });
            for (var i = 0; i < _pattern.get_n_items(); i++) {
                var stop = (Stop) _pattern.get_item (i);
                stop.notify.connect (() => { queue_draw (); });
            }
        }
    }

    private int width;
    private int height;
    private double base_offset;

    public double offset { get; set; }

    private Binding stop_binding;
    private Stop bound_stop;

    construct {
        set_size_request (400, 70);

        set_draw_func ((d, cr, w, h) => {
            cr.rectangle (5, 5, width - 10, height - 40);
            pattern.apply_custom (cr, {15, height / 2}, {width - 15, height / 2}, PatternType.LINEAR);
            cr.fill ();

            for (int i = 0; i < pattern.get_n_items(); i++) {
                Stop s = (Stop) pattern.get_item (i);
                var cx = 15 + (width - 30) * s.offset;
                cr.move_to (cx, height - 35);
                cr.line_to (cx + 10, height - 25);
                cr.line_to (cx + 10, height - 5);
                cr.line_to (cx - 10, height - 5);
                cr.line_to (cx - 10, height - 25);
                cr.close_path ();
                cr.set_source_rgb (0.4, 0.4, 0.4);
                cr.fill ();
                cr.rectangle (cx - 8, height - 23, 16, 16);
                cr.set_source_rgba (s.rgba.red, s.rgba.green, s.rgba.blue, s.rgba.alpha);
                cr.fill ();
            }
        });

        var click_controller = new Gtk.GestureClick ();
        add_controller (click_controller);
        click_controller.pressed.connect ((n, x, y) => {
            if (n == 2) {
                if (height - 35 < y && y < height - 5) {
                    for (int i = 0; i < pattern.get_n_items(); i++) {
                        Stop stop = (Stop) pattern.get_item (i);
                        var cx = 15 + (width - 30) * stop.offset;
                        if (cx - 10 < x && x < cx + 10) {
                            var dialog = new Gtk.ColorChooserDialog (_("Stop Color"), root as Gtk.Window);
                            dialog.use_alpha = true;
                            dialog.rgba = stop.rgba;
                            var old_rgba = stop.rgba;
                            stop.begin ("rgba");
                            dialog.bind_property ("rgba", stop, "rgba");
                            dialog.response.connect ((result) => {
                                if (result != Gtk.ResponseType.OK) {
                                    stop.rgba = old_rgba;
                                }

                                stop.finish ("rgba");
                                dialog.destroy ();
                            });
                            dialog.show ();
                        } else {
                            stop.begin ("offset");
                            bound_stop = stop;
                            stop_binding = bind_property ("offset", stop, "offset");
                        }
                    }
                }
            } else if (5 < y && y < height - 40) {
                var offset = (x - 15) / (width - 30);
                pattern.add_stop (new Stop (offset, pattern.rgba));
            }
        });

        var drag_controller = new Gtk.GestureDrag ();
        add_controller (drag_controller);
        drag_controller.drag_begin.connect ((x, y) => {
            if (height - 35 < y && y < height - 5) {
                for (int i = 0; i < pattern.get_n_items(); i++) {
                    Stop stop = (Stop) pattern.get_item (i);
                    var cx = 15 + (width - 30) * stop.offset;
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
            offset = double.min (1, double.max (0, (offset_x + base_offset) / (width - 30)));
        });

        drag_controller.drag_end.connect ((offset_x, offset_y) => {
            offset = double.min (1, double.max (0, (offset_x + base_offset) / (width - 30)));
            if (stop_binding != null) {
                stop_binding.unbind ();
                stop_binding = null;
                bound_stop.finish ("offset");
            }
        });
    }

    public override void size_allocate (int width, int height, int baseline)  {
        this.width = width;
        this.height = height;
    }
}
