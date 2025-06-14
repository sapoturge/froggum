public class BackupDialog : Gtk.Window {
    public signal void finish (BackupMethod method);

    construct {
        var header = new Gtk.Label (_("Save backup?"));
        var icon = new Gtk.Image.from_icon_name ("document-save-as");
        var summary = new Gtk.Label (_("Your file may contain useful information that Froggum isn't able to load. Saving a backup lets you edit the file without losing access to that information."));

        var texts = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        texts.append (header);
        texts.append (summary);

        var upper_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
        };
        upper_box.append (icon);
        upper_box.append (texts);

        var backup_button = new Gtk.Button.with_label (_("Save Backup"));
        backup_button.add_css_class ("suggested-action");
        backup_button.clicked.connect (() => {
            finish (BackupMethod.BACKUP);
            close ();
        });
        var new_file_button = new Gtk.Button.with_label (_("Save to New File"));
        new_file_button.clicked.connect (() => {
            finish (BackupMethod.NEW_FILE);
            close ();
        });
        var no_backup_button = new Gtk.Button.with_label (_("Don't Create Backup"));
        no_backup_button.add_css_class ("destructive-action");
        no_backup_button.clicked.connect (() => {
            finish (BackupMethod.NO_BACKUP);
            close ();
        });
        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.clicked.connect (() => {
            finish (BackupMethod.CANCEL);
            close ();
        });

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            halign = Gtk.Align.END,
        };
        button_box.append (cancel_button);
        button_box.append (no_backup_button);
        button_box.append (new_file_button);
        button_box.append (backup_button);

        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        layout.append (upper_box);
        layout.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        layout.append (button_box);

        child = layout;

    }
}
