public class EditorView : Gtk.Box {
    public Image image { get; private set; }

    private Gtk.TreeView paths_list;
    private Viewport viewport;

    public EditorView (Image image) {
        this.image = image;
        paths_list.model = image;
        viewport.image = image;
    }
    
    construct {
        var column = new Gtk.TreeViewColumn ();

        var icon = new Gtk.CellRendererPixbuf ();
        column.pack_start (icon, false);
        column.add_attribute (icon, "surface", 0);

        var visibility = new Gtk.CellRendererToggle ();
        visibility.toggled.connect ((path) => {
            Gtk.TreeIter iter;
            image.get_iter_from_string (out iter, path);
            var element = image.get_element (iter);
            element.visible = !element.visible;
        });

        column.pack_start (visibility, false);
        column.add_attribute (visibility, "active", 1);

        var title = new Gtk.CellRendererText ();
        title.editable = true;
        title.edited.connect ((path, new_text) => {
            Gtk.TreeIter iter;
            image.get_iter_from_string (out iter, path);
            image.get_element (iter).title = new_text;
        });

        column.pack_start (title, true);
        column.add_attribute (title, "text", 2);

        paths_list = new Gtk.TreeView ();
        paths_list.headers_visible = false;
        paths_list.reorderable = true;
        paths_list.append_column (column);

        var list_box_scroll = new Gtk.ScrolledWindow (null, null);
        list_box_scroll.propagate_natural_width = true;
        list_box_scroll.add (paths_list);

        var new_path = new Gtk.Button.from_icon_name ("list-add-symbolic");
        new_path.tooltip_text = _("New path");
        new_path.relief = NONE;
        new_path.clicked.connect (() => {
            image.new_path ();
        });

        var new_circle = new Gtk.Button.from_icon_name ("circle-new-symbolic");
        new_circle.tooltip_text = _("New circle");
        new_circle.relief = NONE;
        new_circle.clicked.connect (() => {
            image.new_circle ();
        });

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
            image.duplicate_path ();
        });

        var path_up = new Gtk.Button.from_icon_name ("go-up-symbolic");
        path_up.tooltip_text = _("Move path up");
        path_up.relief = NONE;
        path_up.clicked.connect (() => {
            image.path_up ();
        });

        var path_down = new Gtk.Button.from_icon_name ("go-down-symbolic");
        path_down.tooltip_text = _("Move path down");
        path_down.relief = NONE;
        path_down.clicked.connect (() => {
            image.path_down ();
        });

        var delete_path = new Gtk.Button.from_icon_name ("edit-delete-symbolic");
        delete_path.tooltip_text = _("Delete path");
        delete_path.relief = NONE;
        delete_path.clicked.connect (() => {
            image.delete_path ();
        });

        var task_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        task_bar.pack_start (new_path);
        task_bar.pack_start (new_circle);
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
