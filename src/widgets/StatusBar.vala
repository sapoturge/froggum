public class StatusBar : Gtk.Box {
    private Gtk.Label cursor_x;
    private Gtk.Label cursor_y;
    private Gee.List<SignalManager> bindings;

    public Point cursor_pos {
        set {
            cursor_x.label = "%.2f".printf (value.x);
            cursor_y.label = "%.2f".printf (value.y);
        }
    }

    private class SignalManager {
        public Handle handle;
        public Gtk.Editable x_label;
        public Gtk.Editable y_label;
        public ulong handle_notify;
        public ulong x_insert;
        public ulong y_insert;

        public void disconnect_all () {
            handle.disconnect (handle_notify);
            x_label.disconnect (x_insert);
            y_label.disconnect (y_insert);
        }
    }

    public Handle? handle {
        set {
            var child = get_last_child ();
            while (child != null && child as Gtk.Separator == null) {
                remove (child);
                child = get_last_child ();
            }

            foreach (var binding in bindings) {
                binding.disconnect_all ();
            }

            bindings.clear ();

            if (value != null) {
                append (new Gtk.Label (_("(")));
                var transformed = value as TransformedHandle;
                while (transformed != null) {
                    add_entry (value);
                    append (new Gtk.Image.from_icon_name ("go-next"));
                    append (new Gtk.Label ("%s: (".printf(transformed.name)));
                    value = transformed.base_handle;
                    transformed = value as TransformedHandle;
                }

                add_entry (value);
            } else {
                append (new Gtk.Label (_("No handle selected")));
            }
        }
    }

    private void add_entry (Handle handle) {
        var new_point = handle.point;
        var x_label = new Gtk.EditableLabel ("%.2f".printf (new_point.x)) {
            width_chars = 5,
            max_width_chars = 5,
            xalign = 1,
        };
        var y_label = new Gtk.EditableLabel ("%.2f".printf (new_point.y)) {
            width_chars = 5,
            max_width_chars = 5,
            xalign = 1,
        };
        var x_delegate = x_label.get_delegate ();
        var y_delegate = y_label.get_delegate ();
        var signal_manager = new SignalManager ();
        signal_manager.handle = handle;
        signal_manager.x_label = x_delegate;
        signal_manager.y_label = y_delegate;
        signal_manager.handle_notify = handle.notify["point"].connect (() => {
            var point = handle.point;
            x_label.text = "%.2f".printf (point.x);
            y_label.text = "%.2f".printf (point.y);
        });
        signal_manager.x_insert = x_delegate.insert_text.connect ((text, len, ref position) => {
            var new_text = new StringBuilder ();
            unichar c;
            for (int i = 0; text.get_next_char (ref i, out c); ) {
                if (('0' <= c && c <= '9') || c == '.') {
                    new_text.append_unichar (c);
                }
            }

            SignalHandler.block (x_delegate, signal_manager.x_insert);
            x_delegate.insert_text (new_text.str, (int) new_text.len, ref position);
            SignalHandler.unblock (x_delegate, signal_manager.x_insert);
            Signal.stop_emission_by_name (x_delegate, "insert_text");
        });
        signal_manager.y_insert = y_delegate.insert_text.connect ((text, len, ref position) => {
            var new_text = new StringBuilder ();
            unichar c;
            for (int i = 0; text.get_next_char (ref i, out c); ) {
                if (('0' <= c && c <= '9') || c == '.') {
                    new_text.append_unichar (c);
                }
            }

            var new_position = new_text.len;

            SignalHandler.block (y_delegate, signal_manager.y_insert);
            y_delegate.insert_text (new_text.str, (int) new_position, ref position);
            SignalHandler.unblock (y_delegate, signal_manager.y_insert);
            Signal.stop_emission_by_name (y_delegate, "insert_text");
        });
        bindings.add (signal_manager);
        append (x_label);
        append (new Gtk.Label (_(",")));
        append (y_label);
        append (new Gtk.Label (_(")")));
    }

    construct {
        cursor_x = new Gtk.Label (_("0.0"));
        cursor_y = new Gtk.Label (_("0.0"));
        append (new Gtk.Label (_("Cursor position: (")));
        append (cursor_x);
        append (new Gtk.Label (_(",")));
        append (cursor_y);
        append (new Gtk.Label (_(")")));
        var separator = new Gtk.Separator (Gtk.Orientation.VERTICAL) {
            margin_start = 5,
            margin_end = 5,
        };
        append (separator);
        var label = new Gtk.Label (_("No handle selected."));
        append (label);
        hexpand = true;
        vexpand = false;
        bindings = new Gee.ArrayList<SignalManager> ();
    }
}
