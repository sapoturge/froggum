public class StatusBar : Gtk.Box {
    private Gtk.Label cursor_x;
    private Gtk.Label cursor_y;
    private Gtk.Button expander_button;
    private bool expanded;
    private Gee.List<SignalManager> bindings;
    private Handle _handle;
    private uint finish_id;
    private bool editing;

    public Point cursor_pos {
        set {
            cursor_x.label = "%.2f".printf (value.x);
            cursor_y.label = "%.2f".printf (value.y);
        }
    }

    private class SignalManager {
        public Handle handle;
        public Gtk.Text x_delegate;
        public Gtk.Text y_delegate;
        public Gtk.EventControllerFocus x_focus;
        public Gtk.EventControllerFocus y_focus;
        public ulong handle_notify;
        public ulong x_activate;
        public ulong y_activate;
        public ulong x_deactivate;
        public ulong y_deactivate;
        public ulong x_insert;
        public ulong y_insert;
        public ulong x_changed;
        public ulong y_changed;
        public ulong x_finish;
        public ulong y_finish;

        public void disconnect_all () {
            handle.disconnect (handle_notify);
            x_delegate.disconnect (x_insert);
            y_delegate.disconnect (y_insert);
            x_delegate.disconnect (x_changed);
            y_delegate.disconnect (y_changed);
            x_delegate.disconnect (x_finish);
            y_delegate.disconnect (y_finish);
            x_focus.disconnect (x_activate);
            y_focus.disconnect (y_activate);
            x_focus.disconnect (x_deactivate);
            y_focus.disconnect (y_deactivate);
        }
    }

    public Handle? handle {
        get {
            return _handle;
        }
        set {
            if (editing) {
                editing = false;
                _handle.finish ("point");
            }

            _handle = value;

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
                var element_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                if (expanded) {
                    element_box.append (new Gtk.Label (_("(")));
                    var transformed = value as TransformedHandle;
                    while (transformed != null) {
                        add_entry (element_box, value);
                        append (element_box);
                        append (new Gtk.Image.from_icon_name ("go-next"));
                        element_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                        element_box.append (new Gtk.Label ("%s: (".printf(transformed.name)));
                        value = transformed.base_handle;
                        transformed = value as TransformedHandle;
                    }
                } else {
                    element_box.append (new Gtk.Label (_("(")));
                }

                add_entry (element_box, value);
                append (element_box);
            } else {
                append (new Gtk.Label (_("No handle selected")));
            }

            append (expander_button);
        }
    }

    private void add_entry (Gtk.Box container, Handle handle) {
        var new_point = handle.point;
        var x_delegate = new Gtk.Text () {
            text = "%.2f".printf (new_point.x),
            width_chars = 5,
            max_width_chars = 5,
            xalign = 1,
        };
        var y_delegate = new Gtk.Text () {
            text = "%.2f".printf (new_point.y),
            width_chars = 5,
            max_width_chars = 5,
            xalign = 1,
        };
        var x_focus = new Gtk.EventControllerFocus ();
        x_delegate.add_controller (x_focus);
        var y_focus = new Gtk.EventControllerFocus ();
        y_delegate.add_controller (y_focus);
        var signal_manager = new SignalManager ();
        signal_manager.handle = handle;
        signal_manager.x_delegate = x_delegate;
        signal_manager.y_delegate = y_delegate;
        signal_manager.x_focus = x_focus;
        signal_manager.y_focus = y_focus;
        signal_manager.handle_notify = handle.notify["point"].connect (() => {
            var point = handle.point;
            if (!x_delegate.has_focus) {
                SignalHandler.block (x_delegate, signal_manager.x_insert);
                x_delegate.text = "%.2f".printf (point.x);
                SignalHandler.unblock (x_delegate, signal_manager.x_insert);
            }
            if (!y_delegate.has_focus) {
                SignalHandler.block (y_delegate, signal_manager.y_insert);
                y_delegate.text = "%.2f".printf (point.y);
                SignalHandler.unblock (y_delegate, signal_manager.y_insert);
            }
        });
        signal_manager.x_deactivate = x_focus.leave.connect (() => {
            x_delegate.text = "%.2f".printf (handle.point.x);
            finish_id = Timeout.add (100, () => {
                finish_id = 0;
                editing = false;
                handle.finish ("point");
                return false;
            });
        });
        signal_manager.x_activate = x_focus.enter.connect (() => {
            if (!editing) {
                handle.begin ("point");
                editing = true;
            } else {
                Source.remove (finish_id);
            }
        });
        signal_manager.y_deactivate = y_focus.leave.connect (() => {
            y_delegate.text = "%.2f".printf (handle.point.y);
            finish_id = Timeout.add (100, () => {
                finish_id = 0;
                editing = false;
                handle.finish ("point");
                return false;
            });
        });
        signal_manager.y_activate = y_focus.enter.connect (() => {
            if (!editing) {
                handle.begin ("point");
                editing = true;
            } else {
                Source.remove (finish_id);
            }
        });
        signal_manager.x_insert = x_delegate.insert_text.connect ((text, len, ref position) => {
            if (x_delegate.has_focus) {
                var new_text = new StringBuilder ();
                unichar c;
                new_text.append_len (x_delegate.text, position);
                var start_position = position;
                for (int i = 0; text.get_next_char (ref i, out c); ) {
                    if (('0' <= c && c <= '9') || c == '.') {
                        new_text.append_unichar (c);
                        position += 1;
                    }
                }

                var result = new_text.free_and_steal ();
                SignalHandler.block (x_delegate, signal_manager.x_insert);
                x_delegate.insert_text (result.substring (start_position), position - start_position, ref start_position);
                SignalHandler.unblock (x_delegate, signal_manager.x_insert);
                Signal.stop_emission_by_name (x_delegate, "insert_text");
            }
        });
        signal_manager.x_changed = x_delegate.changed.connect (() => {
            x_delegate.width_chars = int.max (5, x_delegate.text.length);
            if (x_delegate.has_focus) {
                handle.point = { float.parse (x_delegate.text), handle.point.y };
            }
        });
        signal_manager.y_insert = y_delegate.insert_text.connect ((text, len, ref position) => {
            if (y_delegate.has_focus) {
                var new_text = new StringBuilder ();
                unichar c;
                new_text.append_len (y_delegate.text, position);
                var start_position = position;
                for (int i = 0; text.get_next_char (ref i, out c); ) {
                    if (('0' <= c && c <= '9') || c == '.') {
                        new_text.append_unichar (c);
                        position += 1;
                    }
                }

                var result = new_text.free_and_steal ();
                SignalHandler.block (y_delegate, signal_manager.y_insert);
                y_delegate.insert_text (result.substring (start_position), position - start_position, ref start_position);
                SignalHandler.unblock (y_delegate, signal_manager.y_insert);
                Signal.stop_emission_by_name (y_delegate, "insert_text");
            }
        });
        signal_manager.y_changed = y_delegate.changed.connect (() => {
            y_delegate.width_chars = int.max (5, y_delegate.text.length);
            if (y_delegate.has_focus) {
                handle.point = { handle.point.x, float.parse (y_delegate.text) };
            }
        });
        signal_manager.x_finish = x_delegate.activate.connect (() => {
            handle.finish ("point");
            editing = false;
            // Hack to remove input focus
            Gtk.Widget? sibling = x_delegate.get_prev_sibling ();
            container.remove (x_delegate);
            container.insert_child_after (x_delegate, sibling);
        });
        signal_manager.y_finish = y_delegate.activate.connect (() => {
            handle.finish ("point");
            editing = false;
            // Hack to remove input focus
            Gtk.Widget? sibling = y_delegate.get_prev_sibling ();
            container.remove (y_delegate);
            container.insert_child_after (y_delegate, sibling);
        });
        //signal_manager.x_cancel = x_delegate.
        bindings.add (signal_manager);

        container.append (x_delegate);
        container.append (new Gtk.Label (_(",")));
        container.append (y_delegate);
        container.append (new Gtk.Label (_(")")));
    }

    construct {
        var cursor_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        cursor_x = new Gtk.Label (_("0.0"));
        cursor_y = new Gtk.Label (_("0.0"));
        cursor_box.append (new Gtk.Label (_("Cursor position: (")));
        cursor_box.append (cursor_x);
        cursor_box.append (new Gtk.Label (_(",")));
        cursor_box.append (cursor_y);
        cursor_box.append (new Gtk.Label (_(")")));
        append (cursor_box);
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
        expander_button = new Gtk.Button.from_icon_name ("go-next-symbolic");
        expander_button.clicked.connect (() => {
            if (expanded) {
                expanded = false;
                expander_button.icon_name = "go-next-symbolic";
            } else {
                expanded = true;
                expander_button.icon_name = "go-previous-symbolic";
            }

            handle = handle;
        });
        append (expander_button);
        spacing = 10;
    }
}
