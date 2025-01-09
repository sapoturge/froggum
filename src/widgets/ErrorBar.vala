private enum Responses {
    STOP_LOADING,
    ACCEPT_DEFAULT,
    DELETE,
}

public enum BackupMethod {
    CANCEL,
    NO_BACKUP,
    BACKUP,
    NEW_FILE,
}

public class ErrorBar : Adw.Bin {
    private Gtk.InfoBar bar;
    private Gtk.Label header;
    private Gtk.Label message;
    private Gtk.TextBuffer full;

    private Gtk.Button stop_loading_button;
    private Gtk.Button accept_default_button;
    private Gtk.Button delete_element_button;
    private Gtk.Button delete_attribute_button;

    private bool requested_backup;

    public signal void resolve_error ();
    public signal void stop_loading ();
    public signal void make_backup (BackupMethod method);

    public Error? error {
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
            case ErrorKind.UNKNOWN_PROPERTY:
                header.label = _("<big><b>Unknown attribute encountered</b></big>");
                message.label = _("Unrecognized attribute %s encountered..").printf (value.detail);
                break;
            }

            // Reset action buttons by removing all that are there and putting back the relevant
            // ones.
            if (stop_loading_button.parent != null) {
                bar.remove_action_widget (stop_loading_button);
            }

            if (accept_default_button.parent != null) {
                bar.remove_action_widget (accept_default_button);
            }

            if (delete_element_button.parent != null) {
                bar.remove_action_widget (delete_element_button);
            }

            if (delete_attribute_button.parent != null) {
                bar.remove_action_widget (delete_attribute_button);
            }

            // Now put back the appropriate buttons, in order
            if (value.is_delete_element ()) {
                bar.add_action_widget (delete_element_button, Responses.DELETE);
            }

            if (value.is_delete_attribute ()) {
                bar.add_action_widget (delete_attribute_button, Responses.DELETE);
            }

            if (value.has_default ()) {
                bar.add_action_widget (accept_default_button, Responses.ACCEPT_DEFAULT);
            }

            bar.add_action_widget (stop_loading_button, Responses.STOP_LOADING);

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
        bar.map.connect (() => {
            if (bar.revealed) {
                // This needs to be in a signal callback because it only works after it is attached
                // to a window, which happens long after the bar is created and the error is
                // assigned.
                // Theoretically, this should be all that is needed.
                bar.set_default_response (Responses.STOP_LOADING);
                // Unfortunately, (on Windows) it doesn't make the stop loading button actually
                // "selected" for the purpose of activating on hitting enter, so this line is also
                // needed.
                stop_loading_button.grab_focus ();
            }
        });
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
        stop_loading_button = bar.add_button (_("Stop loading"), Responses.STOP_LOADING);
        accept_default_button = bar.add_button (_("Accept default"), Responses.ACCEPT_DEFAULT);
        accept_default_button.add_css_class ("destructive-action");
        delete_attribute_button = bar.add_button (_("Delete attribute"), Responses.DELETE);
        delete_attribute_button.add_css_class ("destructive-action");
        delete_element_button = bar.add_button (_("Delete element"), Responses.DELETE);
        delete_element_button.add_css_class ("destructive-action");
        container.append (header);
        container.append (message);
        container.append (expander);
        bar.add_child (container);
        child = bar;
        bar.response.connect ((response) => {
            switch (response) {
            case Responses.STOP_LOADING:
                stop_loading ();
                break;
            case Responses.ACCEPT_DEFAULT:
            case Responses.DELETE:
                if (!requested_backup) {
                    var dialog = new BackupDialog ();
                    dialog.finish.connect ((response_kind) => make_backup (response_kind));
                    dialog.show ();
                } else {
                    resolve_error ();
                }

                break;
            }
        });
        requested_backup = false;

        make_backup.connect ((method) => {
            if (method != BackupMethod.CANCEL) {
                requested_backup = true;
            }
        });
    }
}
