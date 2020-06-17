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

    private Gtk.ListBox list_box;

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
        this.add (list_box);
    }

    private void create_drawing_area () {
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
            cr.save ();
            cr.scale(zoom, zoom);
            
            image.draw (cr);

            if (zoom > 2) {
                cr.rectangle (0, 0, 16, 16);
                cr.restore ();
                cr.set_source_rgba (0.1, 0.1, 0.1, 1);
                cr.set_line_width (4);
                cr.stroke ();
                cr.set_line_width (2);
                cr.save ();
                cr.scale (zoom, zoom);
               
                if (zoom > 8) {
                    for (var i = 1; i < 16; i++) {
                        cr.move_to (i, 0);
                        cr.line_to (i, 16);
                        cr.move_to (0, i);
                        cr.line_to (16, i);
                    }
                    cr.restore ();
                    cr.set_source_rgba (0.1, 0.1, 0.1, 1);
                    cr.stroke ();
                    cr.save ();
                }
            }
            cr.restore ();
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
