public class EditorView : Gtk.Box {
    private int scroll_x = -8;
    private int scroll_y = -8;
    private int base_x;
    private int base_y;
    private int zoom = 1;
    private int width = 0;
    private int height = 0;
    private bool scrolling = false;

    private Image image;

    public EditorView (Image image) {
        this.image = image;
    }
    
    public void create () {
        var drawing_area = new Gtk.DrawingArea ();
        drawing_area.set_size_request (200, 200);
        drawing_area.add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
        drawing_area.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
        drawing_area.add_events (Gdk.EventMask.BUTTON_MOTION_MASK);
        drawing_area.add_events (Gdk.EventMask.SCROLL_MASK);

        drawing_area.size_allocate.connect ((alloc) => {
            width = alloc.width;
            height = alloc.height;
        });
        drawing_area.draw.connect ((cr) => {
            cr.set_source_rgb (0.4, 0.6, 0.3);
            cr.paint ();

            cr.translate(width/2, height/2);
            cr.translate(scroll_x, scroll_y);
            cr.scale(zoom, zoom);
            
            image.draw (cr);

            return false;
        });
        drawing_area.button_press_event.connect ((event) => {
            scrolling = true;
            base_x = ((int)event.x)-scroll_x;
            base_y = ((int)event.y)-scroll_y;
            return false;
        });
        drawing_area.motion_notify_event.connect ((event) => {
            if (scrolling) {
                scroll_x = ((int)event.x)-base_x;
                scroll_y = ((int)event.y)-base_y;
            }
            drawing_area.queue_draw_area(0, 0, width, height);
            return false;
        });
        drawing_area.button_release_event.connect ((event) => {
            scrolling = false;
            return false;
        });
        drawing_area.scroll_event.connect ((event) => {
            if (event.direction == Gdk.ScrollDirection.UP) {
                zoom *= 2;
                scroll_x *= 2;
                scroll_y *= 2;
            } else if (event.direction == Gdk.ScrollDirection.DOWN & zoom > 1) {
                zoom /= 2;
                scroll_x /= 2;
                scroll_y /= 2;
            }
            drawing_area.queue_draw_area(0, 0, width, height);
            return false;
        });

        drawing_area.expand = true;
        this.add (drawing_area);
    }
}
