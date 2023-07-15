public class EditorView : Gtk.Box {
    public Image image { get; private set; }

    private Gtk.ListView paths_list;
    private Gtk.SingleSelection selection;
    private Viewport viewport;
    private ulong new_button_handler;
    private Gtk.Button new_button;

    public EditorView (Image image) {
        this.image = image;
        selection = new Gtk.SingleSelection (image.tree);
        paths_list.model = selection;
        viewport.image = image;
        image.path_selected.connect ((e) => {
            if (e != null) {
                for (var position = 0; position < image.tree.get_n_items (); position++) {
                    var elem = (Element) image.tree.get_row (position).item;
                    if (elem == e) {
                        selection.selected = position;
                    }
                }
            }
        });
        selection.selection_changed.connect (() => {
            var row = (Gtk.TreeListRow) selection.selected_item;
            var e = (Element) row.item;
            if (e != null) {
                if (image.selected_child != null) {
                    image.selected_child.select (false);
                }

                e.select (true);
            }
        });
        new_button_handler = new_button.clicked.connect (image.new_path);
    }
    
    construct {
/* // This is all being replaced
        var column = new Gtk.TreeViewColumn ();

        / * // This needs to be replaced with a DrawingArea
        var icon = new Gtk.CellRendererPixbuf ();
        column.pack_start (icon, false);
        column.set_cell_data_func (icon, (cell_layout, cell, model, iter) => {
            icon.surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, image.width, image.height);
            var context = new Cairo.Context (icon.surface);
            image.draw_element (context, iter);
        });
        * /

        var visibility = new Gtk.CellRendererToggle ();
        visibility.toggled.connect ((path) => {
            Gtk.TreeIter iter;
            image.get_iter_from_string (out iter, path);
            var element = image.get_element (iter);
            element.visible = !element.visible;
        });

        column.pack_start (visibility, false);
        column.set_cell_data_func (visibility, (cell_layout, cell, model, iter) => {
            visibility.active = image.get_element (iter).visible;
        });

        var title = new Gtk.CellRendererText ();
        title.editable = true;
        title.edited.connect ((path, new_text) => {
            Gtk.TreeIter iter;
            image.get_iter_from_string (out iter, path);
            image.get_element (iter).title = new_text;
        });

        column.pack_start (title, true);
        column.set_cell_data_func (title, (cell_layout, cell, model, iter) => {
            title.text = image.get_element (iter).title;
        });

        / * // PatternButtons don't do anything now
        var fill = new PatternButton ();
        fill.mode = Gtk.CellRendererMode.EDITABLE;
        column.pack_start (fill, false);
        column.set_cell_data_func (fill, (cell_layout, cell, model, iter) => {
            fill.pattern = image.get_element (iter).fill;
        });

        var stroke = new PatternButton ();
        stroke.mode = Gtk.CellRendererMode.EDITABLE;
        column.pack_start (stroke, false);
        column.set_cell_data_func (stroke, (cell_layout, cell, model, iter) => {
            stroke.pattern = image.get_element (iter).stroke;
        });
        * /
*/

        var builder = new Gtk.SignalListItemFactory ();
        builder.setup.connect ((li) => {
            var row = new PathRow ();
            li.child = row;
        });
        builder.bind.connect ((li) => {
            var layout = (PathRow) li.child;
            var row = (Gtk.TreeListRow) li.item;
            while (row.item is Gtk.TreeListRow) {
                row = (Gtk.TreeListRow) row.item;
            }

            var obj = (Element) row.item;

            layout.bind (row, obj);
        });
        builder.unbind.connect ((li) => {
            var layout = (PathRow) li.child;
            layout.unbind ();
        });

        paths_list = new Gtk.ListView (selection, builder);
/*
        paths_list.headers_visible = false;
        paths_list.reorderable = true;
        paths_list.append_column (column);
        paths_list.row_activated.connect ((path, column) => {
            Gtk.TreeIter iter;
            image.get_iter (out iter, path);
            var element = image.get_element (iter);
            element.select (true);
        });
        selection = paths_list.get_selection ();
*/

        var list_box_scroll = new Gtk.ScrolledWindow ();
        list_box_scroll.propagate_natural_width = true;
        list_box_scroll.child = paths_list;
        list_box_scroll.vexpand = true;

        new_button = new Gtk.Button.from_icon_name("list-add-symbolic");

        var new_path = new Gtk.Button () {
            icon_name = "list-add-symbolic",
            label = _("New Path"),
        };
        new_path.clicked.connect (() => {
            image.new_path ();
            new_button.icon_name = "list-add-symbolic";
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_path);
        });

        var new_circle = new Gtk.Button () {
            icon_name = "circle-new-symbolic",
            label = _("New Circle"),
        };
        new_circle.clicked.connect (() => {
            image.new_circle ();
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
        //new_button.icon_name = "list-add-symbolic";
        
        var new_group = new Gtk.Button.from_icon_name ("folder-new-symbolic");
        new_group.tooltip_text = _("New group");
        new_group.has_frame = false;
        new_group.clicked.connect (() => {
            image.new_group ();
        });

        var duplicate_path = new Gtk.Button.from_icon_name ("edit-copy-symbolic");
        duplicate_path.tooltip_text = _("Duplicate path");
        duplicate_path.has_frame = false;
        duplicate_path.clicked.connect (() => {
            // image.duplicate_path (selection.get_selected (null, out iter));
        });

        var path_up = new Gtk.Button.from_icon_name ("go-up-symbolic");
        path_up.tooltip_text = _("Move path up");
        path_up.has_frame = false;
        path_up.clicked.connect (() => {
            var row = image.tree.get_row (selection.selected);
            var prev_row = image.tree.get_row (selection.selected - 1);
            if (row != null && prev_row != null) {
                // Possible cases:
                //  - swap with previous
                //  - move into a group
                //  - move out of a group
                if (prev_row.depth > row.depth) {
                    // TODO: Move into an open group above
                    print ("Moving into groups not implemented\n");
                } else if (prev_row.depth < row.depth) {
                    var elem = row.item as Element;
                    if (elem != null) {
                        elem.swap_up ();
                    }
                } else {
                    // Swap with previous
                    var elem = row.item as Element;
                    if (elem != null) {
                        elem.swap_up ();
                    }
                }
            }
        });

        var path_down = new Gtk.Button.from_icon_name ("go-down-symbolic");
        path_down.tooltip_text = _("Move path down");
        path_down.has_frame = false;
        path_down.clicked.connect (() => {
            var row = image.tree.get_row (selection.selected);
            if (row != null) {
                var elem = row.item as Element;
                if (elem != null) {
                    elem.swap_down ();
                }
            }
        });

        var delete_path = new Gtk.Button.from_icon_name ("edit-delete-symbolic");
        delete_path.tooltip_text = _("Delete path");
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

        viewport = new Viewport ();
        var scrolled = new Gtk.ScrolledWindow ();
        scrolled.child = viewport;
        scrolled.hscrollbar_policy = Gtk.PolicyType.ALWAYS;
        scrolled.vscrollbar_policy = Gtk.PolicyType.ALWAYS;
        scrolled.hexpand = true;

        append (side_bar);
        append (scrolled);

        hexpand = true;
        vexpand = true;
    }
}
