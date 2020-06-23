public class EditorView : Gtk.Box {
    private Image image;

    private Gtk.ListBox list_box;
    private Viewport viewport;

    public EditorView (Image image) {
        this.image = image;
    }
    
    public void create () {
        create_path_view ();
        create_drawing_area ();
    }

    private void create_path_view () {
        list_box = new Gtk.ListBox ();
        image.create_path_rows (list_box);
        pack_start (list_box, false, false, 0);
    }

    private void create_drawing_area () {
        viewport = new Viewport (image);
        /*
        drawing_area.set_size_request (400, 400);
        drawing_area.add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
        drawing_area.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
        drawing_area.add_events (Gdk.EventMask.BUTTON_MOTION_MASK);
        drawing_area.add_events (Gdk.EventMask.SCROLL_MASK);

        drawing_area.button_press_event.connect ((event) => {
            var scaled_x = (event.x - width / 2 + scroll_x) / zoom;
            var scaled_y = (event.y - height / 2 + scroll_y) / zoom;
            if (image.button_press (scaled_x, scaled_y, zoom)) {
                image_handling = true;
                return false;
            }
            scrolling = true;
            base_x = ((int)event.x)-scroll_x;
            base_y = ((int)event.y)-scroll_y;
            return false;
        });
        drawing_area.motion_notify_event.connect ((event) => {
            if (image_handling) {
                image.motion (event);
            }
            if (scrolling) {
                scroll_x = ((int)event.x)-base_x;
                scroll_y = ((int)event.y)-base_y;
                updated = true;
            }
            return false;
        });
        */
        pack_start (viewport, true, true, 0);
    }
}
