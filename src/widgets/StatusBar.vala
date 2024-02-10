public class StatusBar : Gtk.Box {
    private Gee.Map<Handle, ulong> bindings;

    public Handle? handle {
        set {
            var child = get_last_child ();
            while (child != null) {
                remove (child);
                child = get_last_child ();
            }

            foreach (var binding in bindings) {
                binding.key.disconnect (binding.value);
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
        var point = handle.point;
        var xLabel = new Gtk.EditableLabel ("%.2f".printf (point.x)) {
            width_chars = 5,
            max_width_chars = 5,
            xalign = 1,
        };
        var yLabel = new Gtk.EditableLabel ("%.2f".printf (point.y)) {
            width_chars = 5,
            max_width_chars = 5,
            xalign = 1,
        };
        bindings.set (handle, handle.notify["point"].connect (() => {
            point = handle.point;
            xLabel.text = "%.2f".printf (point.x);
            yLabel.text = "%.2f".printf (point.y);
        }));
        append (xLabel);
        append (new Gtk.Label (_(",")));
        append (yLabel);
        append (new Gtk.Label (_(")")));
    }

    construct {
        var label = new Gtk.Label (_("No handle selected."));
        append (label);
        hexpand = true;
        vexpand = false;
        bindings = new Gee.HashMap<Handle, ulong> ();
    }
}
