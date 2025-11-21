public class EditorSidebar : Gtk.Box {
    private Element? _element = null;
    private Segment? _segment = null;
    private Handle? _handle = null;

    public Element? element {
        get {
            return _element;
        }
        set {
            if (value != _element) {
                _element = value;
                refill_element_section ();
            }
        }
    }

    public Segment? segment {
        get {
            return _segment;
        }
        set {
            if (value != _segment) {
                _segment = value;
                refill_segment_section ();
            }
        }
    }

    public Handle? handle {
        get {
            return _handle;
        }
        set {
            if (value != _handle) {
                _handle = value;
                refill_handle_section ();
            }
        }
    }

    private Gtk.Box element_section;
    private Gtk.Box segment_section;
    private Gtk.Box handle_section;

    public EditorSidebar () {}

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        spacing = 5;

        element_section = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        segment_section = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        handle_section = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);

        append (element_section);
        append (segment_section);
        append (handle_section);

        refill_element_section ();
        // Segment and handle sections are default empty
    }

    private void refill_element_section () {
        // If I find a better way to clear a box, I will update this
        var first_child = element_section.get_first_child ();
        while (first_child != null) {
            element_section.remove (first_child);
            first_child = element_section.get_first_child ();
        }

        if (element == null) {
            element_section.append (new Gtk.Label (_("No element selected")));
        } else {
            var options = element.options ();
            fill_section (element_section, options);
        }
    }

    private void refill_segment_section () {
        // If I find a better way to clear a box, I will update this
        var first_child = segment_section.get_first_child ();
        while (first_child != null) {
            segment_section.remove (first_child);
            first_child = segment_section.get_first_child ();
        }

        if (segment != null) {
            var options = segment.options ();
            fill_section (segment_section, options);
        }
    }

    private void refill_handle_section () {
        // If I find a better way to clear a box, I will update this
        var first_child = handle_section.get_first_child ();
        while (first_child != null) {
            handle_section.remove (first_child);
            first_child = handle_section.get_first_child ();
        }

        if (handle != null) {
            var options = handle.options;
            fill_section (handle_section, options);
        }
    }

    private void fill_section (Gtk.Box section, Gee.List<ContextOption> options) {
        foreach (ContextOption option in options) {
            switch (option.option_type) {
            case SEPARATOR:
                break; // Elements shouldn't add their own separators
            case ACTION:
                var button = new Gtk.Button.with_label (option.label);
                button.clicked.connect (() => {
                    option.activate ();
                });
                element_section.append (button);
                break;
            case DELETER:
                var button = new Gtk.Button.with_label (option.label);
                button.add_css_class ("destructive-action");
                button.clicked.connect (() => {
                    option.activate ();
                });
                element_section.append (button);
                break;
            case TOGGLE:
                var button = new Gtk.CheckButton.with_label (option.label);
                bool value = false;
                option.target.get (option.prop, &value);
                button.set_active (value);
                button.toggled.connect (() => {
                    bool val = false;
                    option.target.get (option.prop, &val);
                    option.target.begin (option.prop);
                    option.target.set (option.prop, !val);
                    option.target.finish (option.prop);
                });
                section.append (button);
                break;
            case COLOR:
                Gdk.RGBA? rgba = Gdk.RGBA ();
                option.target.get (option.prop, &rgba);
                var dialog = new Gtk.ColorDialog () {
                    with_alpha = true,
                };
                var button = new Gtk.ColorDialogButton (dialog) {
                    rgba = rgba,
                };
                button.notify["rgba"].connect (() => {
                    option.target.begin (option.prop);
                    option.target.set (option.prop, button.get_rgba ()); // Using button.rgba doesn't compile (too many arguments)
                    option.target.finish (option.prop);
                });
                var label = new Gtk.Label (option.label) {
                    hexpand = true,
                };
                var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                row.append (label);
                row.append (button);
                section.append (row);
                break;
            case OPTIONS:
                var caption = new Gtk.Label (option.label);
                section.append (caption);
                int value = 0;
                option.target.get (option.prop, &value);
                Gtk.ToggleButton first_button = null;

                foreach (Gee.Map.Entry<string, int> variant in option.option_values) {
                    var button = new Gtk.ToggleButton.with_label (variant.key);
                    if (first_button == null) {
                        first_button = button;
                    } else {
                        button.group = first_button;
                    }

                    button.toggled.connect (() => {
                        if (button.active) {
                            option.target.begin (option.prop);
                            option.target.set (option.prop, variant.value);
                            option.target.finish (option.prop);
                        }
                    });
                    if (value == variant.value) {
                        button.active = true;
                    }

                    section.append (button);
                }

                break;
            }
        }
    }
}
