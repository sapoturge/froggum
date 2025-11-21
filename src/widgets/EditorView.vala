public class EditorView : Gtk.Box, ErrorReporter {
    private const string PREFIX = "edit";
    private const string ACTION_NEW_PATH = "new-path";
    private const string ACTION_NEW_CIRCLE = "new-circle";
    private const string ACTION_NEW_ELLIPSE = "new-ellipse";
    private const string ACTION_NEW_RECTANGLE = "new-rectangle";
    private const string ACTION_NEW_LINE = "new-line";
    private const string ACTION_NEW_POLYLINE = "new-polyline";
    private const string ACTION_NEW_POLYGON = "new-polygon";
    private const string ACTION_NEW_GROUP = "new-group";
    private const string ACTION_DUPLICATE = "duplicate";
    private const string ACTION_SWAP_UP = "swap-up";
    private const string ACTION_SWAP_DOWN = "swap-down";
    private const string ACTION_DELETE = "delete";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_NEW_PATH, action_new_path },
        { ACTION_NEW_CIRCLE, action_new_circle },
        { ACTION_NEW_ELLIPSE, action_new_ellipse },
        { ACTION_NEW_RECTANGLE, action_new_rectangle },
        { ACTION_NEW_LINE, action_new_line },
        { ACTION_NEW_POLYLINE, action_new_polyline },
        { ACTION_NEW_POLYGON, action_new_polygon },
        { ACTION_NEW_GROUP, action_new_group },
        { ACTION_DUPLICATE, action_duplicate },
        { ACTION_SWAP_UP, action_swap_up },
        { ACTION_SWAP_DOWN, action_swap_down },
        { ACTION_DELETE, action_delete },
    };

    public signal void close_popovers ();

    public Image image { get; private set; }

    private static Menu default_layers_context_menu;

    private Gtk.ListView paths_list;
    private Gtk.SingleSelection selection;
    private Viewport viewport;
    private StatusBar status_bar;
    private Gtk.InfoBar transform_bar;
    private Gtk.Label transform_label;
    private Gtk.Button new_path;
    private Gtk.Button new_circle;
    private Gtk.Button new_ellipse;
    private Gtk.Button new_rectangle;
    private Gtk.Button new_line;
    private Gtk.Button new_polyline;
    private Gtk.Button new_polygon;
    private Gtk.Button new_group;
    private Gtk.Button duplicate_path;
    private Gtk.Button path_up;
    private Gtk.Button path_down;
    private Gtk.Button delete_path;
    private ErrorBar error_bar;
    private bool error_from_image;

    public signal void create_new ();

    public bool allow_edits {
        get {
            return image.error == null;
        }
        set {
            new_path.sensitive = value;
            new_circle.sensitive = value;
            new_ellipse.sensitive = value;
            new_rectangle.sensitive = value;
            new_line.sensitive = value;
            new_polyline.sensitive = value;
            new_polygon.sensitive = value;
            new_group.sensitive = value;
            duplicate_path.sensitive = value;
            path_up.sensitive = value;
            path_down.sensitive = value;
            delete_path.sensitive = value;
            status_bar.allow_edits = value;
        }
    }

    public EditorView (Image image) {
        var action_group = new SimpleActionGroup ();
        action_group.add_action_entries (ACTION_ENTRIES, this);
        insert_action_group (PREFIX, action_group);

        this.image = image;
        selection = new Gtk.SingleSelection (image.tree);
        paths_list.model = selection;
        viewport.image = image;
        image.path_selected.connect ((e) => {
            if (e != null) {
                Container current_parent = image.selected_child as Container;
                var num_rows = image.tree.n_items;
                var start_rows = num_rows;
                for (var position = 0; position < num_rows; position++) {
                    var elem = (Element) image.tree.get_row (position).item;
                    if (elem == e) {
                        selection.selected = position;
                        // Once elementary updates to Gtk 4.12, this can be replaced with scroll_to
                        var adj = paths_list.vadjustment;
                        adj.upper = (adj.upper - adj.lower) * num_rows / start_rows + adj.lower;
                        adj.value = (position - num_rows + start_rows) * (adj.upper - adj.lower) / num_rows + adj.lower;
                        paths_list.vadjustment = adj;
                        return;
                    } else if (elem as Container == current_parent && current_parent != null) {
                        image.tree.get_row (position).expanded = true;
                        num_rows = image.tree.get_n_items ();
                        current_parent = current_parent.selected_child as Container;
                    }
                }
            }
        });
        image.error_available.connect (() => error_bar.error = image.error);
        error_bar.error = image.error;
        error_from_image = true;
        allow_edits = image.error == null;
        selection.selection_changed.connect (() => {
            var row = (Gtk.TreeListRow) selection.selected_item;
            var e = row.item as Element;
            if (e != null) {
                var cont = e as Container;
                if (cont == null || cont.selected_child == null) {
                    var parent = (Container) image;
                    while (parent != null) {
                        if (parent.selected_child == e ) {
                            return;
                        }

                        parent = parent.selected_child as Container;
                    }
                }

                if (image.has_selected ()) {
                    image.deselect ();
                }

                e.select (true);
            }
        });
        image.apply_transform.connect ((trans, elem) => {
            if (elem == null) {
                transform_bar.revealed = false;
            } else {
                transform_label.label = _("Viewing with the transform of '%s' applied.").printf (elem.title);
                transform_bar.revealed = true;
            }
        });
    }

    static construct {
        default_layers_context_menu = new Menu ();
        default_layers_context_menu.append (_("New Path"), PREFIX + "." + ACTION_NEW_PATH);
        default_layers_context_menu.append (_("New Circle"), PREFIX + "." + ACTION_NEW_CIRCLE);
        default_layers_context_menu.append (_("New Ellipse"), PREFIX + "." + ACTION_NEW_ELLIPSE);
        default_layers_context_menu.append (_("New Rectangle"), PREFIX + "." + ACTION_NEW_RECTANGLE);
        default_layers_context_menu.append (_("New Line"), PREFIX + "." + ACTION_NEW_LINE);
        default_layers_context_menu.append (_("New Polyline"), PREFIX + "." + ACTION_NEW_POLYLINE);
        default_layers_context_menu.append (_("New Polygon"), PREFIX + "." + ACTION_NEW_POLYGON);
        default_layers_context_menu.append (_("New Group"), PREFIX + "." + ACTION_NEW_GROUP);
        default_layers_context_menu.append (_("Duplicate Selected"), PREFIX + "." + ACTION_DUPLICATE);
        default_layers_context_menu.append (_("Shift Up"), PREFIX + "." + ACTION_SWAP_UP);
        default_layers_context_menu.append (_("Shift Down"), PREFIX + "." + ACTION_SWAP_DOWN);
        default_layers_context_menu.append (_("Delete"), PREFIX + "." + ACTION_DELETE);
    }

    construct {
        var edit_sidebar = new EditorSidebar ();

        var builder = new Gtk.SignalListItemFactory ();
        builder.setup.connect ((l) => {
            var li = (Gtk.ListItem) l;
            var row = new PathRow ();
            bind_property ("allow_edits", row, "allow_edits");
            row.allow_edits = allow_edits;
            li.child = row;
            row.request_close_popovers.connect (() => close_popovers ());
            close_popovers.connect (() => row.close_popovers ());
        });
        builder.bind.connect ((l) => {
            var li = (Gtk.ListItem) l;
            var layout = (PathRow) li.child;
            var row = (Gtk.TreeListRow) li.item;
            while (row.item is Gtk.TreeListRow) {
                row = (Gtk.TreeListRow) row.item;
            }

            var obj = (Element) row.item;

            layout.bind (row, obj);
        });
        builder.unbind.connect ((l) => {
            var li = (Gtk.ListItem) l;
            var layout = (PathRow) li.child;
            layout.unbind ();
            // TODO: remove bindings
        });

        paths_list = new Gtk.ListView (selection, builder);
        
        var paths_context_menu = new Gtk.PopoverMenu.from_model (default_layers_context_menu);
        paths_context_menu.set_parent (paths_list);
        var right_click_controller = new Gtk.GestureClick ();
        right_click_controller.set_button (3);
        paths_list.add_controller (right_click_controller);
        right_click_controller.pressed.connect ((n, x, y) => {
            paths_context_menu.pointing_to = {(int) x - 5, (int) y - 5, 10, 10};
            paths_context_menu.popup ();
        });

        var list_box_scroll = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
        };
        list_box_scroll.propagate_natural_width = true;
        list_box_scroll.child = paths_list;
        list_box_scroll.vexpand = true;

        new_path = new Gtk.Button () {
            icon_name = "list-add-symbolic",
            tooltip_text = _("New Path"),
            action_name = PREFIX + "." + ACTION_NEW_PATH,
        };
        new_circle = new Gtk.Button () {
            icon_name = "circle-new-symbolic",
            tooltip_text = _("New Circle"),
            action_name = PREFIX + "." + ACTION_NEW_CIRCLE,
        };
        new_rectangle = new Gtk.Button () {
            icon_name = "rectangle-new-symbolic",
            tooltip_text = _("New Rectangle"),
            action_name = PREFIX + "." + ACTION_NEW_RECTANGLE,
        };
        new_ellipse = new Gtk.Button () {
            icon_name = "ellipse-new-symbolic",
            tooltip_text = _("New Ellipse"),
            action_name = PREFIX + "." + ACTION_NEW_ELLIPSE,
        };
        new_line = new Gtk.Button () {
            icon_name = "line-new-symbolic",
            tooltip_text = _("New Line"),
            action_name = PREFIX + "." + ACTION_NEW_LINE,
        };
        new_polyline = new Gtk.Button () {
            icon_name = "polyline-new-symbolic",
            tooltip_text = _("New Polyline"),
            action_name = PREFIX + "." + ACTION_NEW_POLYLINE,
        };
        new_polygon = new Gtk.Button () {
            icon_name = "polygon-new-symbolic",
            tooltip_text = _("New Polygon"),
            action_name = PREFIX + "." + ACTION_NEW_POLYGON,
        };
        new_group = new Gtk.Button () {
            icon_name = "folder-new-symbolic",
            tooltip_text = _("New group"),
            action_name = PREFIX + "." + ACTION_NEW_GROUP,
        };
        duplicate_path = new Gtk.Button () {
            icon_name = "edit-copy-symbolic",
            tooltip_text = _("Duplicate element"),
            action_name = PREFIX + "." + ACTION_DUPLICATE,
        };
        path_up = new Gtk.Button () {
            icon_name = "go-up-symbolic",
            tooltip_text = _("Move element up"),
            action_name = PREFIX + "." + ACTION_SWAP_UP,
        };
        path_down = new Gtk.Button () {
            icon_name = "go-down-symbolic",
            tooltip_text = _("Move element down"),
            action_name = PREFIX + "." + ACTION_SWAP_DOWN,
        };
        delete_path = new Gtk.Button () {
            icon_name = "edit-delete-symbolic",
            tooltip_text = _("Delete element"),
            action_name = PREFIX + "." + ACTION_DELETE,
        };

        var task_bar = new Gtk.Grid () {
            column_homogeneous = true,
            column_spacing = 0,
            row_homogeneous = true,
            row_spacing = 0,
        };
        task_bar.add_css_class ("linked");
        task_bar.attach (new_path, 1, 1);
        task_bar.attach (new_circle, 2, 1);
        task_bar.attach (new_ellipse, 3, 1);
        task_bar.attach (new_rectangle, 4, 1);
        task_bar.attach (new_line, 1, 2);
        task_bar.attach (new_polyline, 2, 2);
        task_bar.attach (new_polygon, 3, 2);
        task_bar.attach (new_group, 4, 2);
        task_bar.attach (duplicate_path, 1, 3);
        task_bar.attach (path_up, 2, 3);
        task_bar.attach (path_down, 3, 3);
        task_bar.attach (delete_path, 4, 3);

        var side_bar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        side_bar.hexpand = false;
        side_bar.vexpand = true;
        side_bar.append (edit_sidebar);
        side_bar.append (list_box_scroll);
        side_bar.append (task_bar);

        error_bar = new ErrorBar ();
        error_bar.create_new.connect (() => create_new ());
        error_bar.resolve_error.connect (() => resolve_error ());
        error_bar.try_again.connect (() => try_again ());
        error_bar.make_backup.connect ((method) => {
            switch (method) {
            case CANCEL:
                break;
            case NO_BACKUP:
                resolve_error ();
                break;
            case BACKUP:
                var dialog = new Gtk.FileDialog () {
                    initial_file = image.file,
                    title = _("Save backup"),
                };
                dialog.save.begin (root as Gtk.Window, null, (obj, res) => {
                    try {
                        var backup_file = dialog.save.end (res);
                        if (backup_file != null) {
                            image.file.copy (backup_file, 0, null, null);
                        }
                        resolve_error ();
                    } catch (GLib.Error e) {
                        // TODO: report saving error
                    }
                });
                break;
            case NEW_FILE:
                var dialog = new Gtk.FileDialog () {
                    initial_file = image.file,
                    title = _("Save As"),
                };
                dialog.save.begin (root as Gtk.Window, null, (obj, res) => {
                    try {
                        var new_file = dialog.save.end (res);
                        if (new_file != null) {
                            image.file = new_file;
                        }
                        resolve_error ();
                    } catch (GLib.Error e) {
                        // TODO: report saving error
                    }
                });
                break;
            }
        });

        transform_bar = new Gtk.InfoBar () {
            message_type = QUESTION,
            show_close_button = false,
            revealed = false,
        };
        transform_label = new Gtk.Label (_("Viewing with no transform applied."));
        transform_bar.add_child (transform_label);
        transform_bar.add_button (_("Revert view"), 0);
        transform_bar.response.connect ((response) => image.apply_transform (new Transform.identity(), null));

        viewport = new Viewport ();
        var scrolled = new Gtk.ScrolledWindow ();
        scrolled.child = viewport;
        scrolled.hscrollbar_policy = Gtk.PolicyType.ALWAYS;
        scrolled.vscrollbar_policy = Gtk.PolicyType.ALWAYS;
        scrolled.hexpand = true;
        scrolled.vexpand = true;

        viewport.bind_property ("current_element", edit_sidebar, "element");
        viewport.bind_property ("current_segment", edit_sidebar, "segment");
        viewport.bind_property ("current_handle", edit_sidebar, "handle");

        status_bar = new StatusBar ();
        viewport.bind_property ("current_handle", status_bar, "handle");
        viewport.bind_property ("cursor_pos", status_bar, "cursor_pos");

        var main_space = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_space.append (error_bar);
        main_space.append (transform_bar);
        main_space.append (scrolled);
        main_space.append (status_bar);

        var panes = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        panes.start_child = side_bar;
        panes.end_child = main_space;
        panes.resize_start_child = false;
        panes.shrink_start_child = false;
        panes.resize_end_child = true;
        append (panes);

        hexpand = true;
        vexpand = true;
    }

    private void resolve_error () {
        if (error_from_image) {
            image.resolve_error ();
        }

        error_bar.error = image.error;
        error_from_image = true;
        allow_edits = image.error == null;
    }

    public void add_error (Error err) {
        error_from_image = false;
        error_bar.error = err;
    }

    public void recenter () {
        viewport.recenter ();
    }

    public void zoom_in () {
        viewport.zoom_in ();
    }

    public void zoom_out () {
        viewport.zoom_out ();
    }

    private void try_again () {
        var err = image.error;
        image.resolve_error ();

        switch (err.kind) {
        case ErrorKind.CANT_WRITE:
            image.update (); // This triggers a save, after a short delay
            break;
        default:
            image.reload ();
            break;
        }

        error_bar.error = image.error;
        error_from_image = true;
        allow_edits = image.error == null;
    }

    private void action_new_path () { image.new_path (); }
    private void action_new_circle () { image.new_circle (); }
    private void action_new_ellipse () { image.new_ellipse (); }
    private void action_new_rectangle () { image.new_rectangle (); }
    private void action_new_line () { image.new_line (); }
    private void action_new_polyline () { image.new_polyline (); }
    private void action_new_polygon () { image.new_polygon (); }
    private void action_new_group () { image.new_group (); }
    private void action_duplicate () {
        var row = image.tree.get_row (selection.selected);
        var elem = row.item as Element;
        if (elem != null) {
            elem.request_duplicate ();
        }
    }
    private void action_swap_up () {
        var row = image.tree.get_row (selection.selected);
        var prev_row = image.tree.get_row (selection.selected - 1);
        var elem = row.item as Element;
        if (row != null && prev_row != null && elem != null) {
            var into = false;
            if (prev_row.depth > row.depth) {
                into = true;
            } else if (prev_row.depth == row.depth) {
                into = prev_row.expanded;
            }

            elem.swap_up (into);
        }
    }
    private void action_swap_down () {
        var row = image.tree.get_row (selection.selected);
        if (row != null) {
            var elem = row.item as Element;
            if (elem != null) {
                var into = false;
                var next_row = image.tree.get_row (selection.selected + 1);
                if (next_row != null) {
                    into = next_row.expanded;
                }

                elem.swap_down (into);
            }
        }
    }
    private void action_delete () {
        var row = image.tree.get_row (selection.selected);
        if (row != null) {
            var elem = row.item as Element;
            if (elem != null) {
                elem.request_delete ();
            }
        }
    }
}
