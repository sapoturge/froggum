private enum Responses {
    CREATE_NEW,
    SAVE_NEW,
    ACCEPT_DEFAULT,
    DELETE,
    TRY_AGAIN,
    OK, // Used for internal errors to move on
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

    private Gtk.Button create_new_button;
    private Gtk.Button save_new_button;
    private Gtk.Button try_again_button;
    private Gtk.Button reload_button;
    private Gtk.Button accept_default_button;
    private Gtk.Button delete_element_button;
    private Gtk.Button delete_attribute_button;
    private Gtk.Button ok_button;

    private bool requested_backup;

    public signal void resolve_error ();
    public signal void create_new ();
    public signal void try_again ();
    public signal void make_backup (BackupMethod method);

    delegate void ReplaceButtonFunction(Gtk.Button button, bool replace, Responses response);

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
            case ErrorKind.INTERNAL_ERROR:
                header.label = _("<big><b>Internal error</b></big>");
                message.label = _("Error %s encountered.").printf (value.detail);
                break;
            case ErrorKind.CANT_READ:
                header.label = _("<big><b>Unable to read file</b></big>");
                message.label = _("The file '%s' could not be opened for reading").printf (value.detail);
                break;
            case ErrorKind.CANT_WRITE:
                header.label = _("<big><b>Failed to write file</b></big>");
                message.label = _("Failed to write file '%s'.").printf (value.detail);
                break;
            case ErrorKind.INVALID_SVG:
                header.label = _("<big><b>Failed to parse file</b></big>");
                message.label = _("File '%s' is not a valid SVG file.").printf (value.detail);
                break;
            case ErrorKind.INVALID_PROPERTY:
                header.label = _("<big><b>Invalid attribute value</b></big>");
                message.label = _("Invalid property value '%s'. A default value was applied; see preview below.").printf (value.detail);
                break;
            case ErrorKind.MISSING_PROPERTY:
                header.label = _("<big><b>Required attribute missing</b></big>");
                message.label = _("Missing property value '%s'.").printf (value.detail);
                break;
            case ErrorKind.UNKNOWN_ELEMENT:
                header.label = _("<big><b>Unknown element encountered</b></big>");
                message.label = _("Unrecognized element '%s' encountered.").printf (value.detail);
                break;
            case ErrorKind.UNKNOWN_PROPERTY:
                header.label = _("<big><b>Unknown attribute encountered</b></big>");
                message.label = _("Unrecognized attribute '%s' encountered.").printf (value.detail);
                break;
            }

            // Reset action buttons by removing all that are there and putting back the relevant
            // ones.
            ReplaceButtonFunction replace_button = (button, replace, response) => {
                if (button.parent != null) {
                    bar.remove_action_widget (button);
                }

                if (replace) {
                    bar.add_action_widget (button, response);
                }
            };

            // This order is the order they will appear in the bar, from start to end
            replace_button (ok_button, value.is_other(), Responses.OK);
            replace_button (reload_button, value.can_reload(), Responses.TRY_AGAIN);
            replace_button (try_again_button, value.can_try_again(), Responses.TRY_AGAIN);
            replace_button (save_new_button, value.can_save_new(), Responses.SAVE_NEW);
            replace_button (create_new_button, value.can_create_new(), Responses.CREATE_NEW);
            replace_button (accept_default_button, value.has_default(), Responses.ACCEPT_DEFAULT);
            replace_button (delete_attribute_button, value.is_delete_attribute(), Responses.DELETE);
            replace_button (delete_element_button, value.is_delete_element(), Responses.DELETE);

            switch (value.default_action ()) {
            case DefaultAction.CREATE_NEW:
                bar.set_default_response (Responses.CREATE_NEW);
                create_new_button.grab_focus ();
                break;
            case DefaultAction.SAVE_NEW:
                bar.set_default_response (Responses.SAVE_NEW);
                save_new_button.grab_focus ();
                break;
            case DefaultAction.TRY_AGAIN:
                bar.set_default_response (Responses.TRY_AGAIN);
                try_again_button.grab_focus ();
                break;
            case DefaultAction.OTHER:
                bar.set_default_response (Responses.OK);
                ok_button.grab_focus ();
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
        bar.map.connect (() => {
            if (bar.revealed) {
                // This needs to be in a signal callback because it only works after it is attached
                // to a window, which happens long after the bar is created and the error is
                // assigned.
                // Theoretically, this should be all that is needed.
                bar.set_default_response (Responses.CREATE_NEW);
                // Unfortunately, (on Windows) it doesn't make the stop loading button actually
                // "selected" for the purpose of activating on hitting enter, so this line is also
                // needed.
                create_new_button.grab_focus ();
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
        create_new_button = bar.add_button (_("Create new image"), Responses.CREATE_NEW);
        save_new_button = bar.add_button (_("Save to new file"), Responses.SAVE_NEW);
        try_again_button = bar.add_button (_("Try again"), Responses.TRY_AGAIN);
        reload_button = bar.add_button (_("Reload"), Responses.TRY_AGAIN);
        accept_default_button = bar.add_button (_("Accept default"), Responses.ACCEPT_DEFAULT);
        accept_default_button.add_css_class ("destructive-action");
        delete_attribute_button = bar.add_button (_("Delete attribute"), Responses.DELETE);
        delete_attribute_button.add_css_class ("destructive-action");
        delete_element_button = bar.add_button (_("Delete element"), Responses.DELETE);
        delete_element_button.add_css_class ("destructive-action");
        ok_button = bar.add_button (_("OK"), Responses.OK);
        container.append (header);
        container.append (message);
        container.append (expander);
        bar.add_child (container);
        child = bar;
        bar.response.connect ((response) => {
            switch (response) {
            case Responses.CREATE_NEW:
                create_new ();
                break;
            case Responses.SAVE_NEW:
                make_backup (BackupMethod.NEW_FILE);
                resolve_error ();
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
            case Responses.TRY_AGAIN:
                try_again ();
                break;
            case Responses.OK:
                resolve_error ();
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
