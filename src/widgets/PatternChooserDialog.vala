public class PatternChooserDialog : Gtk.Dialog {
    private Pattern _pattern;
    public Pattern pattern {
        get {
            return _pattern;
        }
        set {
            _pattern = value;
            if (value.pattern_type == COLOR) {
                color.rgba = value.rgba;
            }
        }
    }

    private Gtk.ColorButton color;

    construct {
        var pure_color = new Gtk.RadioButton.with_label (null, "Solid Color");
        pure_color.toggled.connect (() => {
            if (pure_color.active) {
                pattern.rgba = color.rgba;
            }
        });

        color = new Gtk.ColorButton ();
        color.use_alpha = true;
        color.color_set.connect (() => {
            pattern.rgba = color.rgba;
        });

        // TODO: Add Gradient section

        var layout = new Gtk.Grid ();
        layout.attach (pure_color, 0, 0);
        layout.attach (color, 1, 0);

        var content_area = get_content_area ();
        content_area.add (layout);

        content_area.show_all ();
    }
}
