public class EditorView : Gtk.Box {
    public Image image { get; private set; }

    private Gtk.ListView paths_list;
    private Gtk.SingleSelection selection;
    private Viewport viewport;
    private StatusBar status_bar;
    private ulong new_button_handler;
    private Gtk.Button new_button;
    private Gtk.InfoBar transform_bar;
    private Gtk.Label transform_label;

    public EditorView (Image image) {
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
        new_button_handler = new_button.clicked.connect (image.new_path);
    }
    
    construct {
        var builder = new Gtk.SignalListItemFactory ();
        builder.setup.connect ((l) => {
            var li = (Gtk.ListItem) l;
            var row = new PathRow ();
            li.child = row;
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
        });

        paths_list = new Gtk.ListView (selection, builder);

        var list_box_scroll = new Gtk.ScrolledWindow ();
        list_box_scroll.propagate_natural_width = true;
        list_box_scroll.child = paths_list;
        list_box_scroll.vexpand = true;

        new_button = new Gtk.Button.from_icon_name("list-add-symbolic");
        new_button.tooltip_text = _("New path");

        var new_path = new Gtk.Button () {
            icon_name = "list-add-symbolic",
            label = _("New Path"),
        };
        new_path.clicked.connect (() => {
            image.new_path ();
            new_button.icon_name = "list-add-symbolic";
            new_button.tooltip_text = _("New path");
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_path);
        });

        var new_circle = new Gtk.Button () {
            icon_name = "circle-new-symbolic",
            label = _("New Circle"),
        };
        new_circle.clicked.connect (() => {
            image.new_circle ();
            new_button.tooltip_text = _("New circle");
            new_button.icon_name = "circle-new-symbolic";
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_circle);
        });

        var new_rectangle = new Gtk.Button () {
            icon_name = "rectangle-new-symbolic",
            label = _("New Rectangle"),
        };
        new_rectangle.clicked.connect (() => {
            image.new_rectangle ();
            new_button.tooltip_text = _("New rectangle");
            new_button.icon_name = "rectangle-new-symbolic";
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_rectangle);
        });

        var new_ellipse = new Gtk.Button () {
            icon_name = "elipse-new-symbolic",
            label = _("New Ellipse"),
        };
        new_ellipse.clicked.connect (() => {
            image.new_ellipse ();
            new_button.tooltip_text = _("New ellipse");
            new_button.icon_name = "ellipse-new-symbolic";
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_ellipse);
        });

        var new_line = new Gtk.Button () {
            icon_name = "line-new-symbolic",
            label = _("New Line"),
        };
        new_line.clicked.connect (() => {
            image.new_line ();
            new_button.tooltip_text = _("New line");
            new_button.icon_name = "line-new-symbolic";
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_line);
        });

        var new_polyline = new Gtk.Button () {
            icon_name = "polyline-new-symbolic",
            label = _("New Polyline"),
        };
        new_polyline.clicked.connect (() => {
            image.new_polyline ();
            new_button.tooltip_text = _("New polyline");
            new_button.icon_name = "polyline-new-symbolic";
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_polyline);
        });

        var new_polygon = new Gtk.Button () {
            icon_name = "polygon-new-symbolic",
            label = _("New Polygon"),
        };
        new_polygon.clicked.connect (() => {
            image.new_polygon ();
            new_button.tooltip_text = _("New polygon");
            new_button.icon_name = "polygon-new-symbolic";
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_polygon);
        });

        var new_menu = new Gtk.Popover ();
        var new_menu_layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        new_menu_layout.append (new_path);
        new_menu_layout.append (new_circle);
        new_menu_layout.append (new_rectangle);
        new_menu_layout.append (new_ellipse);
        new_menu_layout.append (new_line);
        new_menu_layout.append (new_polyline);
        new_menu_layout.append (new_polygon);
        new_menu.child = new_menu_layout;
 
        var new_menu_button = new Gtk.MenuButton();
        new_menu_button.popover = new_menu;
        
        var new_group = new Gtk.Button.from_icon_name ("folder-new-symbolic");
        new_group.tooltip_text = _("New group");
        new_group.has_frame = false;
        new_group.clicked.connect (() => {
            image.new_group ();
        });

        var duplicate_path = new Gtk.Button.from_icon_name ("edit-copy-symbolic");
        duplicate_path.tooltip_text = _("Duplicate element");
        duplicate_path.has_frame = false;
        duplicate_path.clicked.connect (() => {
            var row = image.tree.get_row (selection.selected);
            var elem = row.item as Element;
            if (elem != null) {
                elem.request_duplicate ();
            }
        });

        var path_up = new Gtk.Button.from_icon_name ("go-up-symbolic");
        path_up.tooltip_text = _("Move element up");
        path_up.has_frame = false;
        path_up.clicked.connect (() => {
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
        });

        var path_down = new Gtk.Button.from_icon_name ("go-down-symbolic");
        path_down.tooltip_text = _("Move element down");
        path_down.has_frame = false;
        path_down.clicked.connect (() => {
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
        });

        var delete_path = new Gtk.Button.from_icon_name ("edit-delete-symbolic");
        delete_path.tooltip_text = _("Delete element");
        delete_path.has_frame = false;
        delete_path.clicked.connect (() => {
            var row = image.tree.get_row (selection.selected);
            if (row != null) {
                var elem = row.item as Element;
                if (elem != null) {
                    elem.request_delete ();
                }
            }
        });

        var task_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        task_bar.append (new_button);
        task_bar.append (new_menu_button);
        task_bar.append (new_group);
        task_bar.append (duplicate_path);
        task_bar.append (path_up);
        task_bar.append (path_down);
        task_bar.append (delete_path);
        task_bar.vexpand = false;
        
        var side_bar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        side_bar.hexpand = false;
        side_bar.vexpand = true;
        side_bar.prepend (list_box_scroll);
        side_bar.append (task_bar);

        transform_bar = new Gtk.InfoBar () {
            message_type = QUESTION,
            show_close_button = false,
            revealed = false,
        };
        transform_label = new Gtk.Label (_("Viewing with no transform applied."));
        transform_bar.add_child (transform_label);
        transform_bar.add_button (_("Revert view"), 0);
        transform_bar.response.connect ((response) => image.apply_transform (Cairo.Matrix.identity(), null));

        viewport = new Viewport ();
        var scrolled = new Gtk.ScrolledWindow ();
        scrolled.child = viewport;
        scrolled.hscrollbar_policy = Gtk.PolicyType.ALWAYS;
        scrolled.vscrollbar_policy = Gtk.PolicyType.ALWAYS;
        scrolled.hexpand = true;
        scrolled.vexpand = true;

        status_bar = new StatusBar ();
        viewport.bind_property ("current_handle", status_bar, "handle");
        viewport.bind_property ("cursor_pos", status_bar, "cursor_pos");
  
        var main_space = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
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
}
