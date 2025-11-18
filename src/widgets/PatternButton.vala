public class PatternButton : Gtk.Button {
    public signal void request_close_popovers ();

    private Pattern _pattern;
    public Pattern pattern {
        get {
            return _pattern;
        }
        set {
            _pattern = value;
            view.set_draw_func ((d, cr, w, h) => {
                pattern.apply_custom (cr, {0, 0}, {w, h}, pattern.pattern_type);
                cr.paint ();
            });
            value.update.connect (() => { view.queue_draw (); });
            switch (value.pattern_type) {
                case COLOR:
                    editors.visible_child_name = "color";
                    color_editor.rgba = pattern.rgba;
                    break;
                case LINEAR:
                    editors.visible_child_name = "gradient";
                    linear_radial.active = false;
                    break;
                case RADIAL:
                    editors.visible_child_name = "gradient";
                    linear_radial.active = true;
                    break;
                default:
                    editors.visible_child_name = "none";
                    break;
            }

        }
    }

    public bool is_radial {
        set {
            pattern.begin ("pattern_type");
            if (value) {
                pattern.pattern_type = RADIAL;
            } else {
                pattern.pattern_type = LINEAR;
            }

            pattern.finish ("pattern_type");
        }
    }

    public string pattern_kind {
        set {
            pattern.begin ("pattern_type");
            switch (value) {
                case "color":
                    pattern.pattern_type = PatternType.COLOR;
                    break;
                case "gradient":
                    if (linear_radial.active) {
                        pattern.pattern_type = PatternType.RADIAL;
                    } else {
                        pattern.pattern_type = PatternType.LINEAR;
                    }

                    break;
                default:
                    pattern.pattern_type = PatternType.NONE;
                    break;
            }

            pattern.finish ("pattern_type");
        }
    }

    private Gtk.DrawingArea view;
    private Gtk.Popover editor;
    private Gtk.Stack editors;
    private Gtk.ColorDialogButton color_editor;
    private Granite.ModeSwitch linear_radial;
    private bool currently_open;

    construct {
        view = new Gtk.DrawingArea ();
        view.content_width = 32;
        view.content_height = 32;
        child = view;

        var edit_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);

        var none_editor = new Gtk.Fixed (); // Simplest empty widget I could find.

        var color_dialog = new Gtk.ColorDialog () {
            with_alpha = true,
        };
        color_editor = new Gtk.ColorDialogButton (color_dialog) {
            tooltip_text = _("Select color"),
        };
        color_editor.notify["rgba"].connect (() => {
            pattern.begin ("rgba");
            pattern.rgba = color_editor.get_rgba ();
            pattern.finish ("rgba");
        });

        var gradient_editor = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);

        linear_radial = new Granite.ModeSwitch.from_icon_name ("gradient-linear-symbolic", "gradient-radial-symbolic") {
            primary_icon_tooltip_text = _("Linear"),
            secondary_icon_tooltip_text = _("Radial"),
            tooltip_text = _("Gradient type"),
        };
        linear_radial.bind_property ("active", this, "is_radial");
        var gradient = new GradientEditor ();
        bind_property ("pattern", gradient, "pattern");

        gradient_editor.append (linear_radial);
        gradient_editor.append (gradient);

        editors = new Gtk.Stack () {
            hhomogeneous = false,
            vhomogeneous = false,
        };
        editors.add_titled (none_editor, "none", _("None"));
        editors.add_titled (color_editor, "color", _("Solid Color"));
        editors.add_titled (gradient_editor, "gradient", _("Gradient"));
        editors.visible_child_name = "none";
        editors.bind_property ("visible_child_name", this, "pattern_kind");

        var switcher = new Gtk.StackSwitcher () {
            stack = editors,
        };

        edit_box.append (switcher);
        edit_box.append (editors);

        editor = new Gtk.Popover () {
            child = edit_box,
            autohide = false, // Keep this open while color dialog is open
                              // This does mean it has to be closed manually
        };
        editor.set_parent (this);

        clicked.connect (() => {
            var was_open = currently_open;
            request_close_popovers ();
            if (!was_open) {
                currently_open = true;
                editor.popup ();
            }
        });
    }

    public void close_popover () {
        currently_open = false;
        editor.popdown ();
    }
}
