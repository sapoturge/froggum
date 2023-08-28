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
                case RADIAL:
                    linear_radial.active = true;
                    break;
                default:
                    // Probably Linear, possibly uninitialized
                    // Nothing to do right now.
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

    private Gtk.ToggleButton no_color;
    private Gtk.ToggleButton pure_color;
    private Gtk.ToggleButton gradient;

    private Gtk.ColorButton color;
    private Granite.ModeSwitch linear_radial;
    private GradientEditor editor;
    
    construct {
        no_color = new Gtk.ToggleButton.with_label (_("None"));
        no_color.toggled.connect (() => {
            if (no_color.active) {
                pattern.begin ("pattern_type");
                pattern.pattern_type = PatternType.NONE;
                pattern.finish ("pattern_type");
                swap_sensitivity (PatternType.NONE);
            }
        });
        
        pure_color = new Gtk.ToggleButton.with_label (_("Solid Color"));
        pure_color.group = no_color;
        pure_color.toggled.connect (() => {
            if (pure_color.active) {
                pattern.begin ("pattern_type");
                pattern.pattern_type = PatternType.COLOR;
                pattern.finish ("pattern_type");
                pattern.rgba = color.rgba;
                swap_sensitivity (PatternType.COLOR);
            }
        });

        color = new Gtk.ColorButton ();
        color.use_alpha = true;
        color.color_set.connect (() => {
            pattern.begin ("rgba");
            pattern.rgba = color.rgba;
            pattern.finish ("rgba");
        });
        color.tooltip_text = _("Select color");

        gradient = new Gtk.ToggleButton.with_label (_("Gradient"));
        gradient.group = no_color;
        gradient.toggled.connect (() => {
            if (gradient.active) {
                pattern.begin ("pattern_type");
                pattern.pattern_type = linear_radial.active ? PatternType.RADIAL : PatternType.LINEAR;
                pattern.finish ("pattern_type");
                swap_sensitivity (pattern.pattern_type);
            }
        });

        linear_radial = new Granite.ModeSwitch.from_icon_name ("gradient-linear-symbolic", "gradient-radial-symbolic");
        linear_radial.primary_icon_tooltip_text = _("Linear");
        linear_radial.secondary_icon_tooltip_text = _("Radial");
        linear_radial.bind_property ("active", this, "is_radial");
        linear_radial.tooltip_text = _("Gradient type");

        editor = new GradientEditor ();
        bind_property ("pattern", editor, "pattern");

        var color_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        color_row.append (pure_color);
        color_row.append (color);

        var gradient_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        gradient_row.append (gradient);
        gradient_row.append (linear_radial);

        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        layout.append (no_color);
        layout.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        layout.append (color_row);
        layout.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        layout.append (gradient_row);
        layout.append (editor);

        var content_area = get_content_area ();
        content_area.append (layout);
    }

    private void swap_sensitivity (PatternType new_type) {
        linear_radial.sensitive = false;
        color.sensitive = false;
        editor.sensitive = false;
        switch (new_type) {
            case COLOR:
                color.sensitive = true;
                pure_color.active = true;
                break;
            case LINEAR:
            case RADIAL:
                linear_radial.sensitive = true;
                editor.sensitive = true;
                gradient.active = true;
                break;
            case NONE:
                no_color.active = true;
                break;
        }
    }
}
