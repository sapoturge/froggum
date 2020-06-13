public class EditorView : Gtk.Box {
    private double scroll_x = -8;
    private double scroll_y = -8;
    private double base_x;
    private double base_y;
    private int zoom = 0;
    private int width = 0;
    private int height = 0;
    private bool scrolling = false;
    
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
            cr.scale(Math.pow(2, zoom), Math.pow(2, zoom));
            cr.translate(scroll_x, scroll_y);
            
            cr.rectangle (0, 0, 16, 16);
            cr.set_source_rgb (0.6, 0.3, 0.4);
            cr.fill ();

            return false;
        });
        drawing_area.button_press_event.connect ((event) => {
            scrolling = true;
            base_x = (event.x-width/2)/Math.pow(2, zoom)-scroll_x;
            base_y = (event.y-height/2)/Math.pow(2, zoom)-scroll_y;
            return false;
        });
        drawing_area.motion_notify_event.connect ((event) => {
            if (scrolling) {
                scroll_x = (event.x-width/2)/Math.pow(2, zoom)-base_x;
                scroll_y = (event.y-height/2)/Math.pow(2, zoom)-base_y;
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
                zoom += 1;
            } else if (event.direction == Gdk.ScrollDirection.DOWN & zoom > 0) {
                zoom -= 1;
            }
            drawing_area.queue_draw_area(0, 0, width, height);
            return false;
        });

        this.add (drawing_area);
    }
}
