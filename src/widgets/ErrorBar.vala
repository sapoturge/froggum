public class ErrorBar : Adw.Bin {
    private Gtk.Revealer bar;
    private Gtk.Label header;
    private Severity last_severity;

    public Error error {
        set {
            switch (value.kind) {
            case ErrorKind.NO_ERROR:
                header.label = _("No error found.");
                break;
            case ErrorKind.CANT_READ:
                header.label = _("Can't read file %s").printf (value.detail);
                break;
            case ErrorKind.CANT_WRITE:
                header.label = _("Failed to write file %s").printf (value.detail);
                break;
            case ErrorKind.INVALID_SVG:
                header.label = _("%s is not a valid SVG file").printf (value.detail);
                break;
            case ErrorKind.INVALID_PROPERTY:
                header.label = _("Invalid property value %s").printf (value.detail);
                break;
            case ErrorKind.MISSING_PROPERTY:
                header.label = _("Missing property value %s").printf (value.detail);
                break;
            case ErrorKind.UNKNOWN_ELEMENT:
                header.label = _("Unrecognized element %s encountered.").printf (value.detail);
                break;
            case ErrorKind.UNKNOWN_ATTRIBUTE:
                header.label = _("Unrecognized attribute %s encountered.").printf (value.detail);
                break;
            }

            switch (last_severity) {
            case NO_ERROR:
                bar.remove_css_class ("info");
                break;
            case WARNING:
                bar.remove_css_class ("warning");
                break;
            case ERROR:
                bar.remove_css_class ("error");
                break;
            }

            switch (value.severity) {
            case NO_ERROR:
                bar.add_css_class ("info");
                bar.reveal_child = false;
                break;
            case WARNING:
                bar.add_css_class ("warning");
                bar.reveal_child = true;
                break;
            case ERROR:
                bar.add_css_class ("error");
                bar.reveal_child = true;
                break;
            }

            last_severity = value.severity;
        }
    }

    public ErrorBar () {}

    construct {
        bar = new Gtk.Revealer () {
            reveal_child = false,
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
        };
        var container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12,
            margin_bottom = 12,
        };
        header = new Gtk.Label ("<big><b>No Error</b></big>") {
            use_markup = true,
        };
        container.append (header);
        bar.child = container;
        child = bar;
    }
}
