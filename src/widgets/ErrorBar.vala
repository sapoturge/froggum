public class ErrorBar : Adw.Bin {
    private Gtk.InfoBar bar;
    private Gtk.Label header;
    private Gtk.TextBuffer full;

    public Error error {
        set {
            // This isn't localized
            full.text = value.full_message;

            // This is localized
            switch (value.kind) {
            case ErrorKind.NO_ERROR:
                header.label = _("<big><b>No error found.</b></big>");
                break;
            case ErrorKind.CANT_READ:
                header.label = _("<big><b>Can't read file %s</b></big>").printf (value.detail);
                break;
            case ErrorKind.CANT_WRITE:
                header.label = _("<big><b>Failed to write file %s</b></big>").printf (value.detail);
                break;
            case ErrorKind.INVALID_SVG:
                header.label = _("<big><b>%s is not a valid SVG file</b></big>").printf (value.detail);
                break;
            case ErrorKind.INVALID_PROPERTY:
                header.label = _("<big><b>Invalid property value %s</b></big>").printf (value.detail);
                break;
            case ErrorKind.MISSING_PROPERTY:
                header.label = _("<big><b>Missing property value %s</b></big>").printf (value.detail);
                break;
            case ErrorKind.UNKNOWN_ELEMENT:
                header.label = _("<big><b>Unrecognized element %s encountered.</b></big>").printf (value.detail);
                break;
            case ErrorKind.UNKNOWN_ATTRIBUTE:
                header.label = _("<big><b>Unrecognized attribute %s encountered.</b></big>").printf (value.detail);
                break;
            }

            switch (value.severity) {
            case NO_ERROR:
                bar.message_type = Gtk.MessageType.INFO;
                bar.revealed = false;
                break;
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
        var container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12,
            margin_bottom = 12,
            hexpand = true,
        };
        header = new Gtk.Label ("<big><b>No Error</b></big>") {
            use_markup = true,
        };
        full = new Gtk.TextBuffer (null);
        var full_message = new Gtk.TextView.with_buffer (full);
        var expander = new Gtk.Expander (null) {
            label_widget = header,
            child = full_message,
            hexpand = true,
        };
        container.append (expander);
        bar.add_child (container);
        child = bar;
    }
}
