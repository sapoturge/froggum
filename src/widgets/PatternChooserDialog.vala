public class PatternChooserDialog : Gtk.Dialog {
    private Pattern _pattern;
    public Pattern pattern {
        get {
            return _pattern;
        }
        set {
            _pattern = value;
            switch (value.pattern_type) {
                case COLOR:
                    color.rgba = value.rgba;
                    break;
                case LINEAR:
                    // Nothing to do right now.
                    break;
                case RADIAL:
                    linear_radial.active = true;
                    break;
            }
            swap_sensitivity (value.pattern_type);
        }
    }

    public bool is_radial {
        set {
            if (value) {
                pattern.pattern_type = RADIAL;
            } else {
                pattern.pattern_type = LINEAR;
            }
        }
    }

    private Gtk.RadioButton no_color;
    private Gtk.RadioButton pure_color;
    private Gtk.RadioButton gradient;

    private Gtk.ColorButton color;
    // private Granite.ModeSwitch linear_radial;
    private Gtk.Switch linear_radial;

    construct {
        no_color = new Gtk.RadioButton.with_label (null, _("None"));
        no_color.toggled.connect (() => {
            if (no_color.active) {
                pattern.pattern_type = PatternType.NONE;
                swap_sensitivity (PatternType.NONE);
            }
        });
        
        pure_color = new Gtk.RadioButton.with_label_from_widget (no_color, _("Solid Color"));
        pure_color.toggled.connect (() => {
            if (pure_color.active) {
                pattern.pattern_type = PatternType.COLOR;
                pattern.rgba = color.rgba;
                swap_sensitivity (PatternType.COLOR);
            }
        });

        color = new Gtk.ColorButton ();
        color.use_alpha = true;
        color.color_set.connect (() => {
            pattern.rgba = color.rgba;
        });

        gradient = new Gtk.RadioButton.with_label_from_widget (pure_color, "Gradient");
        gradient.toggled.connect (() => {
            if (gradient.active) {
                pattern.pattern_type = linear_radial.active ? PatternType.RADIAL : PatternType.LINEAR;
                swap_sensitivity (pattern.pattern_type);
            }
        });

        /*
        linear_radial = new Granite.ModeSwitch.from_icon_name ("gradient-linear-symbolic", "gradient-radial-symbolic");
        linear_radial.primary_icon_tooltip_text = _("Linear");
        linear_radial.secondary_icon_tooltip_text = _("Radial");
        linear_radial.bind_property ("active", this, "is_radial");
        /*/
        this.linear_radial = new Gtk.Switch ();
        this.linear_radial.bind_property ("active", this, "is_radial");

        var linear = new Gtk.Label (_("Linear"));
        var radial = new Gtk.Label (_("Radial"));
        var linear_radial = new Gtk.Grid ();
        linear_radial.attach (linear, 0, 0);
        linear_radial.attach (this.linear_radial, 1, 0);
        linear_radial.attach (radial, 2, 0);

        var layout = new Gtk.Grid ();
        layout.attach (no_color, 0, 0);
        layout.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 1, 3);
        layout.attach (pure_color, 0, 2);
        layout.attach (color, 1, 2);
        layout.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 3, 3);
        layout.attach (gradient, 0, 4);
        layout.attach (linear_radial, 1, 4);

        var content_area = get_content_area ();
        content_area.add (layout);

        content_area.show_all ();
    }

    private void swap_sensitivity (PatternType new_type) {
        linear_radial.sensitive = false;
        color.sensitive = false;
        switch (new_type) {
            case COLOR:
                color.sensitive = true;
                pure_color.active = true;
                break;
            case LINEAR:
            case RADIAL:
                linear_radial.sensitive = true;
                gradient.active = true;
                break;
            case NONE:
                no_color.active = true;
                break;
        }
    }
}
