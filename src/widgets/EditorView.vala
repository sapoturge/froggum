public class EditorView : Gtk.Box {
    public Image image { get; private set; }

    private Gtk.TreeView paths_list;
    private Gtk.TreeSelection selection;
    private Viewport viewport;
    private ulong new_button_handler;
    private Gtk.MenuToolButton new_button;

    public EditorView (Image image) {
        this.image = image;
        paths_list.model = image;
        viewport.image = image;
        new_button_handler = new_button.clicked.connect (image.new_path);
    }
    
    construct {
        var column = new Gtk.TreeViewColumn ();

        var icon = new Gtk.CellRendererPixbuf ();
        column.pack_start (icon, false);
        column.set_cell_data_func (icon, (cell_layout, cell, model, iter) => {
            icon.surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, image.width, image.height);
            var context = new Cairo.Context (icon.surface);
            image.draw_element (context, iter);
        });

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

        paths_list = new Gtk.TreeView ();
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

        var list_box_scroll = new Gtk.ScrolledWindow (null, null);
        list_box_scroll.propagate_natural_width = true;
        list_box_scroll.add (paths_list);

        new_button = new Gtk.MenuToolButton (null, null);

        var new_path = new Gtk.MenuItem ();
        var new_path_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        var new_path_label = new Gtk.Label (_("New Path"));
        var new_path_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        new_path_box.add (new_path_icon);
        new_path_box.add (new_path_label);
        new_path.add (new_path_box);
        new_path.activate.connect (() => {
            image.new_path ();
            new_button.icon_widget = new_path_icon;
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_path);
        });

        var new_circle = new Gtk.MenuItem ();
        var new_circle_icon = new Gtk.Image.from_icon_name ("circle-new-symbolic", Gtk.IconSize.MENU);
        var new_circle_label = new Gtk.Label (_("New Circle"));
        var new_circle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        new_circle_box.add (new_circle_icon);
        new_circle_box.add (new_circle_label);
        new_circle.add (new_circle_box);
        new_circle.activate.connect (() => {
            image.new_circle ();
            new_button.icon_widget = new_circle_icon;
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_circle);
        });

        var new_rectangle = new Gtk.MenuItem ();
        var new_rectangle_icon = new Gtk.Image.from_icon_name ("rectangle-new-symbolic", Gtk.IconSize.MENU);
        var new_rectangle_label = new Gtk.Label (_("New Rectangle"));
        var new_rectangle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        new_rectangle_box.add (new_rectangle_icon);
        new_rectangle_box.add (new_rectangle_label);
        new_rectangle.add (new_rectangle_box);
        new_rectangle.activate.connect (() => {
            image.new_rectangle ();
            new_button.icon_widget = new_rectangle_icon;
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_rectangle);
        });

        var new_ellipse = new Gtk.MenuItem ();
        var new_ellipse_icon = new Gtk.Image.from_icon_name ("ellipse-new-symbolic", Gtk.IconSize.MENU);
        var new_ellipse_label = new Gtk.Label (_("New Ellipse"));
        var new_ellipse_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        new_ellipse_box.add (new_ellipse_icon);
        new_ellipse_box.add (new_ellipse_label);
        new_ellipse.add (new_ellipse_box);
        new_ellipse.activate.connect (() => {
            image.new_ellipse ();
            new_button.icon_widget = new_ellipse_icon;
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_ellipse);
        });

        var new_line = new Gtk.MenuItem ();
        var new_line_icon = new Gtk.Image.from_icon_name ("line-new-symbolic", Gtk.IconSize.MENU);
        var new_line_label = new Gtk.Label (_("New Line"));
        var new_line_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        new_line_box.add (new_line_icon);
        new_line_box.add (new_line_label);
        new_line.add (new_line_box);
        new_line.activate.connect (() => {
            image.new_line ();
            new_button.icon_widget = new_line_icon;
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_line);
        });

        var new_polyline = new Gtk.MenuItem ();
        var new_polyline_icon = new Gtk.Image.from_icon_name ("polyline-new-symbolic", Gtk.IconSize.MENU);
        var new_polyline_label = new Gtk.Label (_("New Polyline"));
        var new_polyline_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        new_polyline_box.add (new_polyline_icon);
        new_polyline_box.add (new_polyline_label);
        new_polyline.add (new_polyline_box);
        new_polyline.activate.connect (() => {
            image.new_polyline ();
            new_button.icon_widget = new_polyline_icon;
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_polyline);
        });

        var new_polygon = new Gtk.MenuItem ();
        var new_polygon_icon = new Gtk.Image.from_icon_name ("polygon-new-symbolic", Gtk.IconSize.MENU);
        var new_polygon_label = new Gtk.Label (_("New Polygon"));
        var new_polygon_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        new_polygon_box.add (new_polygon_icon);
        new_polygon_box.add (new_polygon_label);
        new_polygon.add (new_polygon_box);
        new_polygon.activate.connect (() => {
            image.new_polygon ();
            new_button.icon_widget = new_polygon_icon;
            new_button.disconnect (new_button_handler);
            new_button_handler = new_button.clicked.connect (image.new_polygon);
        });

        var new_menu = new Gtk.Menu ();
        new_menu.add (new_path);
        new_menu.add (new_circle);
        new_menu.add (new_rectangle);
        new_menu.add (new_ellipse);
        new_menu.add (new_line);
        new_menu.add (new_polyline);
        new_menu.add (new_polygon);
 
        new_menu.show_all ();

        new_button.set_menu (new_menu);
        new_button.icon_name = "list-add-symbolic";

        var new_group = new Gtk.Button.from_icon_name ("folder-new-symbolic");
        new_group.tooltip_text = _("New group");
        new_group.relief = NONE;
        new_group.clicked.connect (() => {
            image.new_group ();
        });

        var duplicate_path = new Gtk.Button.from_icon_name ("edit-copy-symbolic");
        duplicate_path.tooltip_text = _("Duplicate path");
        duplicate_path.relief = NONE;
        duplicate_path.clicked.connect (() => {
            Gtk.TreeIter iter;
            if (selection.get_selected (null, out iter)) {
                image.duplicate_path (iter);
            }
        });

        var path_up = new Gtk.Button.from_icon_name ("go-up-symbolic");
        path_up.tooltip_text = _("Move path up");
        path_up.relief = NONE;
        path_up.clicked.connect (() => {
            Gtk.TreeIter iter;
            if (selection.get_selected (null, out iter)) {
                image.path_up (iter);
            }
        });

        var path_down = new Gtk.Button.from_icon_name ("go-down-symbolic");
        path_down.tooltip_text = _("Move path down");
        path_down.relief = NONE;
        path_down.clicked.connect (() => {
            Gtk.TreeIter iter;
            if (selection.get_selected (null, out iter)) {
                image.path_down (iter);
            }
        });

        var delete_path = new Gtk.Button.from_icon_name ("edit-delete-symbolic");
        delete_path.tooltip_text = _("Delete path");
        delete_path.relief = NONE;
        delete_path.clicked.connect (() => {
            Gtk.TreeIter iter;
            if (selection.get_selected (null, out iter)) {
                image.delete_path (iter);
            }
        });

        var task_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        task_bar.pack_start (new_button);
        task_bar.pack_start (new_group);
        task_bar.pack_start (duplicate_path);
        task_bar.pack_start (path_up);
        task_bar.pack_start (path_down);
        task_bar.pack_start (delete_path);
        
        var side_bar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        side_bar.pack_start (list_box_scroll, true, true, 0);
        side_bar.pack_end (task_bar, false, false, 0);

        viewport = new Viewport ();
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (viewport);
        scrolled.hscrollbar_policy = Gtk.PolicyType.ALWAYS;
        scrolled.vscrollbar_policy = Gtk.PolicyType.ALWAYS;

        pack_start (side_bar, false, false, 0);
        pack_start (scrolled, true, true, 0);
    }
}
