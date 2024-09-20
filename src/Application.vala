public class FroggumApplication : Gtk.Application {
    private uint configure_id;
    private bool activated = false;
    private bool will_open = false;

    public static Settings settings;

    private Gtk.ApplicationWindow main_window;
    private Adw.TabView notebook;
    private Gtk.FileDialog dialog;

    public FroggumApplication () {
        Object (
            application_id: "io.github.sapoturge.froggum",
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    public SimpleActionGroup actions { get; construct; }

    public const string ACTION_UNDO = "action_undo";
    public const string ACTION_REDO = "action_redo";

    static construct {
        settings = new Settings ("io.github.sapoturge.froggum");
    }

    construct {
        var undo_action = new SimpleAction ("action_undo", null);
        undo_action.activate.connect (() => {
            var tab = notebook.get_selected_page ();
            var editor = tab.child;
            if (editor is EditorView) {
                var image = ((EditorView) editor).image;
                image.undo ();
            }
        });

        var redo_action = new SimpleAction ("action_redo", null);
        redo_action.activate.connect (() => {
            var tab = notebook.get_selected_page ();
            var editor = tab.child;
            if (editor is EditorView) {
                var image = ((EditorView) editor).image;
                image.redo ();
            }
        });

        actions = new SimpleActionGroup ();
        actions.add_action (undo_action);
        actions.add_action (redo_action);

        set_accels_for_action ("froggum.action_undo", {"<Control>Z", null});
        set_accels_for_action ("froggum.action_redo", {"<Control>Y", null});
        undo_action.set_enabled (true);
        redo_action.set_enabled (true);
    }

    protected override void activate () {
        Gtk.IconTheme default_theme = new Gtk.IconTheme ();
        default_theme.add_resource_path ("/io/github/sapoturge/froggum");

        main_window = new Gtk.ApplicationWindow (this);
        main_window.insert_action_group ("froggum", actions);
        main_window.title = _("Froggum - Untitled");

        if (settings.get_boolean ("window-maximized")) {
            main_window.maximize ();
        }

        main_window.notify["maximized"].connect (() => {
            if (configure_id != 0) {
                Source.remove (configure_id);
            }

            configure_id = Timeout.add (100, () => {
                configure_id = 0;
                if (main_window.maximized) {
                    settings.set_boolean ("window-maximized", true);
                } else {
                    settings.set_boolean ("window-maximized", false);
                }

                return false;
            });
        });

        var header = new Gtk.HeaderBar ();
        header.decoration_layout = "close:maximize";
        header.show_title_buttons = true;

        notebook = new Adw.TabView ();

        notebook.notify["selected-page"].connect((param) => {
            var page = notebook.selected_page;
            var child = page.child;
            var editor = child as EditorView;
            if (editor != null) {
                main_window.title = _("Froggum - %s").printf (page.title);
                settings.set_string ("focused-file", editor.image.file.get_uri ());
            } else {
                main_window.title = _("Froggum - New Icon");
            }
        });

        notebook.page_attached.connect (() => { recalculate_open_files (); });
        notebook.page_detached.connect (() => { recalculate_open_files (); });
        notebook.page_reordered.connect (() => { recalculate_open_files (); });

        var save_button = new Gtk.Button.from_icon_name ("document-save-as");
        save_button.tooltip_text = _("Save as new file");
        save_button.clicked.connect (() => {
            dialog = new Gtk.FileDialog () {
                title = _("untitled.svg"),
            };
            dialog.save.begin (main_window, null, (obj, res) => {
                try {
                    var file = dialog.save.end (res);
                    if (file != null) {
                        var tab = notebook.selected_page;
                        var editor = tab.child as EditorView;
                        if (editor != null) {
                            editor.image.file = file;
                            tab.title = file.get_basename ();
                            main_window.title = _("Froggum - %s").printf (tab.title);
                            settings.set_string ("focused-file", file.get_uri ());
                        }

                        recalculate_open_files ();
                    }
                } catch (GLib.Error e) {
                    // TODO: Inform user that save failed
                }
            });
        });

        header.pack_start (save_button);

        var undo_button  = new Gtk.Button.from_icon_name ("edit-undo");
        undo_button.action_name = "froggum.action_undo";
        undo_button.tooltip_text = _("Undo");
        var redo_button  = new Gtk.Button.from_icon_name ("edit-redo");
        redo_button.action_name = "froggum.action_redo";
        redo_button.tooltip_text = _("Redo");

        header.pack_start (undo_button);
        header.pack_start (redo_button);

        main_window.set_titlebar (header);

        var new_button = new Gtk.Button.from_icon_name ("list-add-symbolic");
        new_button.clicked.connect (() => {
            new_tab ();
        });
        new_button.tooltip_text = _("New icon");

        notebook.hexpand = true;
        notebook.vexpand = true;

        var last_files = settings.get_strv ("open-files");
        var focused_file = settings.get_string ("focused-file");

        Adw.TabPage focused = null;

        foreach (string file in last_files) {
            if (file != "") {
                var real_file = File.new_for_uri (file);
                var image = new Image.load (real_file);
                var editor = new EditorView (image);
                editor.hexpand = true;
                editor.vexpand = true;
                var tab = notebook.append (editor);
                tab.title = real_file.get_basename ();
                if (file == focused_file) {
                    focused = tab;
                }
            }
        }

        if (notebook.n_pages == 0 && !will_open) {
            new_tab ();
        } else if (focused != null) {
            notebook.selected_page = focused;
        }

        var tabs = new Adw.TabBar () {
            view = notebook,
            autohide = false,
            start_action_widget = new_button,
        };

        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        layout.append (tabs);
        layout.append (notebook);
        main_window.child = layout;
        main_window.show ();

        activated = true;
    }

    protected override int command_line (ApplicationCommandLine command_line) {
        string[] args = command_line.get_arguments ();

        if (args.length > 1) {
            will_open = true;
        }

        if (!activated) {
            activate ();
        }

        foreach (unowned string arg in args[1:args.length]) {
            var file = File.new_for_commandline_arg (arg);
            var image = new Image.load (file);
            var editor = new EditorView (image);
            editor.hexpand = true;
            editor.vexpand = true;
            var tab = notebook.append (editor);
            tab.title = file.get_basename ();
        }

        recalculate_open_files ();

        return 0;
    }

    protected override void open (File[] files, string hint) {
        will_open = true;

        if (!activated) {
             activate ();
        }

        foreach (File file in files) {
            var image = new Image.load (file);
            var editor = new EditorView (image);
            editor.hexpand = true;
            editor.vexpand = true;
            var tab = notebook.append (editor);
            tab.title = file.get_basename ();
        }

        recalculate_open_files ();
    }

    private void new_image (int width, int height, Adw.TabPage tab) {
        var radius = int.min (int.min (width, height) / 8, 16) + 0.5;
        var segments = new PathSegment[] {
            new PathSegment.line (width - radius * 2, radius),
            new PathSegment.arc (width - radius, radius * 2, width - radius * 2, radius * 2, radius, radius, 0, false),
            new PathSegment.line (width - radius, height - radius * 2),
            new PathSegment.arc (width - radius * 2, height - radius, width - radius * 2, height - radius * 2, radius, radius, 0, false),
            new PathSegment.line (radius * 2, height - radius),
            new PathSegment.arc (radius, height - radius * 2, radius * 2, height - radius * 2, radius, radius, 0, false),
            new PathSegment.line (radius, radius * 2),
            new PathSegment.arc (radius * 2, radius, radius * 2, radius * 2, radius, radius, 0, false),
        };
        var path = new Path.with_pattern (segments, new Pattern.color ({0.3f, 0.3f, 0.3f, 1f}), new Pattern.color ({0.1f, 0.1f, 0.1f, 1f}), _("Default Path"));
        var circle = new Circle (width / 2, height / 2, double.min (width / 2, height / 2), new Pattern.color ({0.4f, 0.5f, 0.6f, 1f}), new Pattern.color ({0.7f, 0.6f, 0.5f, 1f}));
        var image = new Image (width, height, {path, circle});
        var editor = new EditorView (image);
        editor.hexpand = true;
        editor.vexpand = true;

        var new_tab = notebook.add_page (editor, tab);
        new_tab.title = _("New Image");
        notebook.close_page (tab);
    }

    private void open_image (Adw.TabPage tab) {
        dialog = new Gtk.FileDialog();
        dialog.open.begin (main_window, null, (obj, res) => {
            try {
                var file = dialog.open.end (res);
                if (file != null) {
                    var image = new Image.load (file);
                    var editor = new EditorView (image);
                    editor.hexpand = true;
                    editor.vexpand = true;
                    var new_tab = notebook.add_page (editor, tab);
                    new_tab.title = file.get_basename ();
                    notebook.close_page (tab);
                    recalculate_open_files ();
                }
            } catch (GLib.Error e) {
                // TODO: Inform user of failed open
            }
        });
    }

    private void new_tab () {
         var inner_layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
         var tab = notebook.append (inner_layout);
         tab.title = _("New Image");

         var title = new Gtk.Label (_("Create a new icon:"));

         var n16 = new Gtk.Button ();
         n16.label = _("16 \u00D7 16");
         n16.clicked.connect (() => {
             new_image (16, 16, tab);
         });

         var n24 = new Gtk.Button ();
         n24.label = _("24 \u00D7 24");
         n24.clicked.connect (() => {
             new_image (24, 24, tab);
         });

         var n32 = new Gtk.Button ();
         n32.label = _("32 \u00D7 32");
         n32.clicked.connect (() => {
             new_image (32, 32, tab);
         });

         var n48 = new Gtk.Button ();
         n48.label = _("48 \u00D7 48");
         n48.clicked.connect (() => {
             new_image (48, 48, tab);
         });

         var n64 = new Gtk.Button ();
         n64.label = _("64 \u00D7 64");
         n64.clicked.connect (() => {
             new_image (64, 64, tab);
         });

         var n128 = new Gtk.Button ();
         n128.label = _("128 \u00D7 128");
         n128.clicked.connect (() => {
             new_image (128, 128, tab);
         });

         var standard_grid = new Gtk.Grid ();
         standard_grid.row_spacing = 4;
         standard_grid.column_spacing = 4;
         standard_grid.attach (n16, 0, 0, 1, 1);
         standard_grid.attach (n24, 1, 0, 1, 1);
         standard_grid.attach (n32, 2, 0, 1, 1);
         standard_grid.attach (n48, 0, 1, 1, 1);
         standard_grid.attach (n64, 1, 1, 1, 1);
         standard_grid.attach (n128, 2, 1, 1, 1);
         standard_grid.column_homogeneous = true;

         var custom_width = new Gtk.SpinButton.with_range (1, 2048, 1);
         var custom_height = new Gtk.SpinButton.with_range (1, 2018, 1);

         var ncustom = new Gtk.Button ();
         ncustom.label = _("Custom:");
         ncustom.clicked.connect (() => {
             new_image ((int) custom_width.value, (int) custom_height.value, tab);
         });

         var custom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
         custom_box.append (ncustom);
         custom_box.append (new Gtk.Label("Width:"));
         custom_box.append (custom_width);
         custom_box.append (new Gtk.Label ("Height:"));
         custom_box.append (custom_height);

         var new_side = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);
         new_side.append (title);
         new_side.append (standard_grid);
         new_side.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
         new_side.append (custom_box);

         var open_button = new Gtk.Button ();
         open_button.label = _("Open");
         open_button.clicked.connect (() => {
             open_image (tab);
         });

         var open_side = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
         open_side.append (open_button);
         open_side.valign = Gtk.Align.CENTER;

         inner_layout.append (new_side);
         inner_layout.append (new Gtk.Separator (Gtk.Orientation.VERTICAL));
         inner_layout.append (open_side);

         inner_layout.halign = Gtk.Align.CENTER;
         inner_layout.valign = Gtk.Align.CENTER;

         notebook.selected_page = tab;
    }

    private void recalculate_open_files () {
        var filenames = new string[] {};
        for (int i = 0; i < notebook.n_pages; i++) {
            var tab = notebook.get_nth_page (i);
            var editor = tab.child as EditorView;
            if (editor != null && editor.image.file != null) {
                filenames += editor.image.file.get_uri ();
            }
        }
        settings.set_strv ("open-files", filenames);

        if (notebook.selected_page != null) {
            var child = notebook.selected_page.child;
            var editor = child as EditorView;
            if (editor != null) {
                if (editor.image.file != null) {
                    main_window.title = _("Froggum - %s").printf (editor.image.name);
                    settings.set_string ("focused-file", editor.image.file.get_uri ());
                } else {
                    main_window.title = _("Froggum - Untitled");
                }
            } else {
                main_window.title = _("Froggum - New Icon");
            }
        }
    }

    public static int main (string[] args) {
        var app = new FroggumApplication ();
        return app.run (args);
    }
}
