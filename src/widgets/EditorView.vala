public class EditorView : Gtk.Box {
    private Image image;

    private Gtk.ListBox list_box;
    private Viewport viewport;

    public EditorView (Image image) {
        this.image = image;
        list_box.bind_model (image, (path) => {
            return new PathRow (image, (Path) path);
        });
        viewport.image = image;
    }
    
    construct {
        list_box = new Gtk.ListBox ();
        pack_start (list_box, false, false, 0);

        viewport = new Viewport ();
        pack_start (viewport, true, true, 0);
    }
}
