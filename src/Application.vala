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
    public const string ACTION_ZOOM_IN = "action_zoom_in";
    public const string ACTION_ZOOM_OUT = "action_zoom_out";
    public const string ACTION_SAVE_AS = "action_save_as";
    public const string ACTION_RECENTER = "action_recenter";

    static construct {
        settings = new Settings ("io.github.sapoturge.froggum");
    }

    construct {
        actions = new SimpleActionGroup ();

        var save_as_action = new SimpleAction(ACTION_SAVE_AS, null);
        save_as_action.activate.connect (() => { save_as (); });
        actions.add_action (save_as_action);
        save_as_action.set_enabled (true);
        set_accels_for_action ("froggum.action_save_as", {"<Control><Shift>S", null});

        var undo_action = new SimpleAction ("action_undo", null);
        undo_action.activate.connect (() => {
            var tab = notebook.get_selected_page ();
            var editor = tab.child;
            if (editor is EditorView) {
                var image = ((EditorView) editor).image;
                image.undo ();
            }
        });
        actions.add_action (undo_action);
        undo_action.set_enabled (true);
        set_accels_for_action ("froggum.action_undo", {"<Control>Z", null});

        var redo_action = new SimpleAction ("action_redo", null);
        redo_action.activate.connect (() => {
            var tab = notebook.get_selected_page ();
            var editor = tab.child;
            if (editor is EditorView) {
                var image = ((EditorView) editor).image;
                image.redo ();
            }
        });
        actions.add_action (redo_action);
        redo_action.set_enabled (true);
        set_accels_for_action ("froggum.action_redo", {"<Control>Y", null});

        var recenter_action = new SimpleAction ("action_recenter", null);
        recenter_action.activate.connect (() => {
            var tab = notebook.get_selected_page ();
            var editor = tab.child;
            if (editor is EditorView) {
                editor.recenter ();
            }
        });
        actions.add_action (recenter_action);
        recenter_action.set_enabled (true);
        set_accels_for_action ("froggum.action_recenter", {"<Control>0", null});

        var zoom_in_action = new SimpleAction ("action_zoom_in", null);
        zoom_in_action.activate.connect (() => {
            var tab = notebook.get_selected_page ();
            var editor = tab.child;
            if (editor is EditorView) {
                editor.zoom_in ();
            }
        });
        actions.add_action (zoom_in_action);
        zoom_in_action.set_enabled (true);
        set_accels_for_action ("froggum.action_zoom_in", {"<Control>plus", "<Control>equal", null});

        var zoom_out_action = new SimpleAction ("action_zoom_out", null);
        zoom_out_action.activate.connect (() => {
            var tab = notebook.get_selected_page ();
            var editor = tab.child;
            if (editor is EditorView) {
                editor.zoom_out ();
            }
        });
        actions.add_action (zoom_out_action);
        zoom_out_action.set_enabled (true);
        set_accels_for_action ("froggum.action_zoom_out", {"<Control>minus", null});
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
        save_button.action_name = "froggum.action_save_as";

        header.pack_start (save_button);

        var undo_button  = new Gtk.Button.from_icon_name ("edit-undo");
        undo_button.action_name = "froggum.action_undo";
        undo_button.tooltip_text = _("Undo");
        var redo_button  = new Gtk.Button.from_icon_name ("edit-redo");
        redo_button.action_name = "froggum.action_redo";
        redo_button.tooltip_text = _("Redo");

        header.pack_start (undo_button);
        header.pack_start (redo_button);

        var center_button = new Gtk.Button.from_icon_name ("zoom-fit-best");
        center_button.action_name = "froggum.action_recenter";
        center_button.tooltip_text = _("Recenter image");
        var zoom_in_button = new Gtk.Button () {
            icon_name = "zoom-in",
            action_name = "froggum.action_zoom_in",
            tooltip_text = _("Zoom in"),
        };
        var zoom_out_button = new Gtk.Button () {
            icon_name = "zoom-out",
            action_name = "froggum.action_zoom_out",
            tooltip_text = _("Zoom out"),
        };

        header.pack_start (center_button);
        header.pack_start (zoom_in_button);
        header.pack_start (zoom_out_button);

        main_window.set_titlebar (header);

        var new_button = new Gtk.Button.from_icon_name ("list-add-symbolic");
        new_button.clicked.connect (() => {
            make_new_tab (null);
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
                editor.create_new.connect (() => make_new_tab (tab));
                if (file == focused_file) {
                    focused = tab;
                }
            }
        }

        if (notebook.n_pages == 0 && !will_open) {
            make_new_tab (null);
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
            editor.create_new.connect (() => make_new_tab (tab));
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
            editor.create_new.connect (() => make_new_tab (tab));
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
        editor.create_new.connect (() => make_new_tab (new_tab));
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
                    editor.create_new.connect (() => make_new_tab (new_tab));
                    new_tab.title = file.get_basename ();
                    notebook.close_page (tab);
                    recalculate_open_files ();
                }
            } catch (GLib.Error e) {
                if (e.code == Gtk.DialogError.DISMISSED) {
                    // The user didn't pick a file
                    // No "error handling" necessary
                } else if (e.code == Gtk.DialogError.CANCELLED) {
                    // Froggum closed the dialog (this shouldn't ever happen)
                    // Still no response required
                } else {
                    // Something actually went wrong
                    var inner = tab.child as ErrorReporter;
                    if (inner != null) {
                        inner.add_error (new Error.glib_error (e));
                    }
                }
            }
        });
    }

    private void make_new_tab (Adw.TabPage? old_tab) {
        var new_page = new NewTab ();
        Adw.TabPage tab;
        if (old_tab == null) {
            tab = notebook.append (new_page);
        } else {
            tab = notebook.add_page (new_page, old_tab);
            notebook.close_page (old_tab);
        }
        tab.title = _("New Image");
        new_page.new_image.connect ((width, height) => new_image (width, height, tab));
        new_page.open_image.connect (() => open_image (tab));

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

    private void save_as () {
        var tab = notebook.selected_page;
        var editor = tab.child as EditorView;
        if (editor != null) {
            dialog = new Gtk.FileDialog () {
                title = _("untitled.svg"),
            };
            dialog.save.begin (main_window, null, (obj, res) => {
                try {
                    var file = dialog.save.end (res);
                    if (file != null) {
                        editor.image.file = file;
                        tab.title = file.get_basename ();
                        main_window.title = _("Froggum - %s").printf (tab.title);
                        settings.set_string ("focused-file", file.get_uri ());
                        recalculate_open_files ();
                    }
                } catch (GLib.Error e) {
                    if (e.code == Gtk.DialogError.DISMISSED) {
                        // The user didn't pick a file
                        // No "error handling" necessary
                    } else if (e.code == Gtk.DialogError.CANCELLED) {
                        // Froggum closed the dialog (this shouldn't ever happen)
                        // Still no response required
                    } else {
                        // Something actually went wrong
                        editor.add_error (new Error.glib_error (e));
                    }
                }
            });
        }
    }

    public static int main (string[] args) {
        var app = new FroggumApplication ();
        return app.run (args);
    }
}
