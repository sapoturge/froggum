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

        var line_label = new Gtk.Label (_("Line Width")) {
            hexpand = true
        };
        var line_preview = new LinePreview () {
            vexpand = true
        };
        var line_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        line_row.append (line_label);
        line_row.append (line_preview);
        var line_size = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0.1, 1, 0.1);
        settings.bind ("line-thickness", line_size.adjustment, "value", DEFAULT);

        var grid_size_display = new SnapPreview ();
        var grid_size_label = new Gtk.Label (_("Snap Distance")) {
            hexpand = true,
        };
        var grid_size_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        grid_size_row.append (grid_size_label);
        grid_size_row.append (grid_size_display);
        var grid_size = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 1, 40, 1);
        settings.bind ("snap-tolerance", grid_size.adjustment, "value", DEFAULT);
        var grid_subsection = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        grid_subsection.append (grid_size_row);
        grid_subsection.append (grid_size);

        var grid_label = new Gtk.Label (_("Show Grid")) {
            hexpand = true,
            halign = Gtk.Align.START,
        };
        var grid_enable = new Gtk.Switch ();
        grid_enable.notify["state"].connect (() => {
            grid_subsection.visible = grid_enable.state;
            if (grid_enable.state) {
                grid_enable.tooltip_text = _("Hide grid (Ctrl-G)");
            } else {
                grid_enable.tooltip_text = _("Show grid (Ctrl-G)");
            }
        });
        settings.bind ("show-grid", grid_enable, "state", DEFAULT);
        grid_enable.set_active (settings.get_boolean ("show-grid"));
        grid_subsection.visible = grid_enable.state;
        var grid_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        grid_row.append (grid_label);
        grid_row.append (grid_enable);

        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        layout.append (handle_label);
        layout.append (handle_size);
        layout.append (line_row);
        layout.append (line_size);
        layout.append (grid_row);
        layout.append (grid_subsection);
        child = layout;
    }
}
