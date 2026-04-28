public class SettingsView : Gtk.Popover {
    public Settings settings { get; construct; }

    public SettingsView (Settings settings) {
        Object (
            settings: settings
        );
    }

    construct {
        var handle_label = new Gtk.Label(_("Handle Size"));
        var handle_size = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 3, 30, 1);
        settings.bind ("handle-radius", handle_size.adjustment, "value", DEFAULT);

        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        layout.append (handle_label);
        layout.append (handle_size);
        child = layout;
    }
}
