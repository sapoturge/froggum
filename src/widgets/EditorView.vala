public class EditorView : Gtk.Box {
    public Image image { get; private set; }

    private Gtk.ListBox list_box;
    private Viewport viewport;

    public EditorView (Image image) {
        this.image = image;
        list_box.bind_model (image, (path) => {
            var row = new PathRow (image, (Path) path);
            row.show_all ();
            return row;
        });
        list_box.row_activated.connect ((row) => {
            ((PathRow) row).path.select (true);
        });
        viewport.image = image;
    }
    
    construct {
        list_box = new Gtk.ListBox ();

        var new_path = new Gtk.Button ();
        // TODO: Replace these with icons and tool tips
        new_path.label = "New Path";
        new_path.clicked.connect (() => {
            image.new_path ();
        });

        var duplicate_path = new Gtk.Button ();
        duplicate_path.label = "Duplicate Path";
        duplicate_path.clicked.connect (() => {
            image.duplicate_path ();
        });

        var path_up = new Gtk.Button ();
        path_up.label = "Move Up";
        path_up.clicked.connect (() => {
            image.path_up ();
        });

        var path_down = new Gtk.Button ();
        path_down.label = "Move Path Down";
        path_down.clicked.connect (() => {
            image.path_down ();
        });

        var delete_path = new Gtk.Button ();
        delete_path.label = "Delete Path";
        delete_path.clicked.connect (() => {
            image.delete_path ();
        });

        var task_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        task_bar.pack_start (new_path);
        task_bar.pack_start (duplicate_path);
        task_bar.pack_start (path_up);
        task_bar.pack_start (path_down);
        task_bar.pack_start (delete_path);
        
        var side_bar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        side_bar.pack_start (list_box, false, false, 0);
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
