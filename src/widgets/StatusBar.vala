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

            append (new Gtk.Label (_("(")));

            if (value != null) {
                var transformed = value as TransformedHandle;
                while (transformed != null) {
                    var local = value;
                    var point = local.point;
                    var xLabel = new Gtk.Label ("%.2f".printf (point.x));
                    var yLabel = new Gtk.Label ("%.2f".printf (point.y));
                    bindings.set (local, local.notify["point"].connect (() => {
                        point = local.point;
                        xLabel.label = "%.2f".printf (point.x);
                        yLabel.label = "%.2f".printf (point.y);
                    }));
                    append (xLabel);
                    append (new Gtk.Label (_(",")));
                    append (yLabel);
                    append (new Gtk.Label (_(")")));
                    append (new Gtk.Image.from_icon_name ("go-next"));
                    append (new Gtk.Label ("%s: (".printf(transformed.name)));
                    value = transformed.base_handle;
                    transformed = value as TransformedHandle;
                }

                var point = value.point;
                var xLabel = new Gtk.Label ("%.2f".printf (point.x));
                var yLabel = new Gtk.Label ("%.2f".printf (point.y));
                bindings.set (value, value.notify["point"].connect (() => {
                    point = value.point;
                    xLabel.label = "%.2f".printf (point.x);
                    yLabel.label = "%.2f".printf (point.y);
                }));
                append (xLabel);
                append (new Gtk.Label (_(",")));
                append (yLabel);
                append (new Gtk.Label (_(")")));
            } else {
                append (new Gtk.Label (_("No handle selected")));
            }
        }
    }

    construct {
        var label = new Gtk.Label (_("No handle selected."));
        append (label);
        hexpand = true;
        vexpand = false;
        bindings = new Gee.HashMap<Handle, ulong> ();
    }
}
