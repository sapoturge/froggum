public class SettingsView : Gtk.Popover {
    public Settings settings { get; construct; }

    public SettingsView (Settings settings) {
        Object (
            settings: settings
        );
    }

    construct {
        var handle_label = new Gtk.Label (_("Handle Size"));
        var handle_size = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        var small = new Gtk.CheckButton () {
            name = "handle-small",
            tooltip_text = _("Small handles"),
            action_name = "froggum." + FroggumApplication.ACTION_HANDLE_SIZE,
            action_target = 4.0,
        };
        var medium = new Gtk.CheckButton () {
            group = small,
            name = "handle-medium",
            tooltip_text = _("Medium handles"),
            action_name = "froggum." + FroggumApplication.ACTION_HANDLE_SIZE,
            action_target = 8.0,
        };
        var large = new Gtk.CheckButton () {
            group = small,
            name = "handle-large",
            tooltip_text = _("Large handles"),
            action_name = "froggum." + FroggumApplication.ACTION_HANDLE_SIZE,
            action_target = 12.0,
        };
        var extra_large = new Gtk.CheckButton () {
            group = small,
            name = "handle-extra-large",
            tooltip_text = _("Extra large handles"),
            action_name = "froggum." + FroggumApplication.ACTION_HANDLE_SIZE,
            action_target = 16.0,
        };
        handle_size.append (small);
        handle_size.append (medium);
        handle_size.append (large);
        handle_size.append (extra_large);

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
