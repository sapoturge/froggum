public class SettingsView : Gtk.Popover {
    public Settings settings { get; construct; }

    public SettingsView (Settings settings) {
        Object (
            settings: settings
        );
    }

    construct {
        var handle_label = new Gtk.Label (_("Handle Size"));
        var handle_size = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 3, 30, 1);
        settings.bind ("handle-radius", handle_size.adjustment, "value", DEFAULT);

        var line_label = new Gtk.Label (_("Line Width"));
        var line_size = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 3, 30, 1);
        settings.bind ("line-thickness", line_size.adjustment, "value", DEFAULT);

        var grid_label = new Gtk.Label (_("Snap Distance"));
        var grid_size = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 20, 1);
        settings.bind ("snap-tolerance", grid_size.adjustment, "value", DEFAULT);

        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        layout.append (handle_label);
        layout.append (handle_size);
        layout.append (line_label);
        layout.append (line_size);
        layout.append (grid_label);
        layout.append (grid_size);
        child = layout;
    }
}
