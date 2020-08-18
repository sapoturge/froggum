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

    public double offset { get; set; }

    private Binding stop_binding;

    construct {
        set_size_request (400, 70);

        draw.connect ((cr) => {
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

        size_allocate.connect ((alloc) => {
            width = alloc.width;
            height = alloc.height;
        });

        events |= Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK;

        button_press_event.connect ((ev) => {
            if (stop_binding != null) {
                stop_binding.unbind ();
                stop_binding = null;
            }
            if (height - 35 < ev.y && ev.y < height - 5) {
                for (int i = 0; i < pattern.get_n_items(); i++) {
                    Stop stop = (Stop) pattern.get_item (i);
                    var cx = 15 + (width - 30) * stop.offset;
                    if (cx - 10 < ev.x && ev.x < cx + 10) {
                        if (ev.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) {
                            var dialog = new Gtk.ColorChooserDialog (_("Stop Color"), null);
                            dialog.use_alpha = true;
                            dialog.rgba = stop.rgba;
                            var old_rgba = stop.rgba;
                            dialog.bind_property ("rgba", stop, "rgba");
                            var result = dialog.run ();
                            if (result != Gtk.ResponseType.OK) {
                                print ("%d\n", result);
                                stop.rgba = old_rgba;
                            }
                            dialog.destroy ();
                        } else {
                            stop_binding = bind_property ("offset", stop, "offset");
                        }
                        return false;
                    }
                }
            } else if (5 < ev.y && ev.y < height - 40) {
                var offset = (ev.x - 15) / (width - 30);
                pattern.add_stop (new Stop (offset, pattern.rgba));
            }
        });

        button_release_event.connect ((ev) => {
            if (stop_binding != null) {
                stop_binding.unbind ();
                stop_binding = null;
            }
        });

        events |= Gdk.EventMask.BUTTON_MOTION_MASK;

        motion_notify_event.connect ((ev) => {
            offset = double.min (1, double.max (0, (ev.x - 15) / (width - 30)));
        });
    }
}
