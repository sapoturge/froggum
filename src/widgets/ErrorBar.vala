public class ErrorBar : Adw.Bin {
    private Gtk.InfoBar bar;
    private Gtk.Label header;
    private Gtk.Label message;
    private Gtk.TextBuffer full;

    public signal void stop_loading ();

    public Error error {
        set {
            if (value == null) {
                bar.revealed = false;
                return;
            }

            // This isn't localized
            full.text = value.full_message;

            // This is localized
            switch (value.kind) {
            case ErrorKind.CANT_READ:
                header.label = _("<big><b>Unable to read file</b></big>");
                message.label = _("The file %s could not be opened for reading").printf (value.detail);
                break;
            case ErrorKind.CANT_WRITE:
                header.label = _("<big><b>Failed to write file</b></big>");
                message.label = _("Failed to write file %s.").printf (value.detail);
                break;
            case ErrorKind.INVALID_SVG:
                header.label = _("<big><b>Failed to parse file</b></big>");
                message.label = _("%s is not a valid SVG file.").printf (value.detail);
                break;
            case ErrorKind.INVALID_PROPERTY:
                header.label = _("<big><b>Invalid attribute value</b></big>");
                message.label = _("Invalid property value %s.").printf (value.detail);
                break;
            case ErrorKind.MISSING_PROPERTY:
                header.label = _("<big><b>Required attribute missing</b></big>");
                message.label = _("Missing property value %s.").printf (value.detail);
                break;
            case ErrorKind.UNKNOWN_ELEMENT:
                header.label = _("<big><b>Unknown element encountered</b></big>");
                message.label = _("Unrecognized element %s encountered..").printf (value.detail);
                break;
            case ErrorKind.UNKNOWN_ATTRIBUTE:
                header.label = _("<big><b>Unknown attribute encountered</b></big>");
                message.label = _("Unrecognized attribute %s encountered..").printf (value.detail);
                break;
            }

            switch (value.severity) {
            case WARNING:
                bar.message_type = Gtk.MessageType.WARNING;
                bar.revealed = true;
                break;
            case ERROR:
                bar.message_type = Gtk.MessageType.ERROR;
                bar.revealed = true;
                break;
            }
        }
    }

    public ErrorBar () {}

    construct {
        bar = new Gtk.InfoBar ();
        var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12,
            margin_bottom = 12,
            hexpand = true,
        };
        header = new Gtk.Label (_("<big><b>No Error</b></big>")) {
            use_markup = true,
            halign = Gtk.Align.START,
        };
        message = new Gtk.Label (_("No details.")) {
            halign = Gtk.Align.START,
        };
        full = new Gtk.TextBuffer (null);
        var full_message = new Gtk.TextView.with_buffer (full);
        var expander = new Gtk.Expander (null) {
            label_widget = new Gtk.Label (_("Details")),
            child = full_message,
            hexpand = true,
        };
        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            halign = Gtk.Align.END,
        };
        var stop_loading_button = new Gtk.Button.with_label (_("Stop loading"));
        stop_loading_button.clicked.connect (() => stop_loading ());
        stop_loading_button.add_css_class ("suggested-action");
        button_box.append (stop_loading_button);
        container.append (header);
        container.append (message);
        container.append (expander);
        container.append (button_box);
        bar.add_child (container);
        child = bar;
    }
}
