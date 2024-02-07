public class StatusBar : Gtk.Box {
    private ulong binding;
    private Handle? _handle;

    public Handle? handle {
        set {
            var child = get_last_child ();
            while (child != null) {
                remove (child);
                child = get_last_child ();
            }

            if (binding != 0) {
                _handle.disconnect (binding);
            }

            binding = 0;
            _handle = value;

            if (value != null) {
                var transformed = value as TransformedHandle;
                if (transformed != null) {
                    append (new Gtk.Label (transformed.name));
                }

                var point = value.point;
                var xLabel = new Gtk.Label ("%.2f".printf (point.x));
                var yLabel = new Gtk.Label ("%.2f".printf (point.y));
                binding = value.notify["point"].connect (() => {
                    point = value.point;
                    xLabel.label = "%.2f".printf (point.x);
                    yLabel.label = "%.2f".printf (point.y);
                });
                append (xLabel);
                append (yLabel);
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
    }
}
