public class LinePreview : Gtk.Widget {
    private double radius;
    private double width;
    private bool hovering;

    public LinePreview () {}

    construct {
        FroggumApplication.settings.changed["line-thickness"].connect (() => {
            width = radius * FroggumApplication.settings.get_double ("line-thickness");
            queue_draw ();
        });
        FroggumApplication.settings.changed["handle-radius"].connect (() => {
            radius = FroggumApplication.settings.get_double ("handle-radius");
            set_size_request ((int) (radius * 4) + 2, (int) (radius * 2) + 2);
            queue_draw ();
        });
        radius = FroggumApplication.settings.get_double ("handle-radius");
        set_size_request ((int) (radius * 4) + 2, (int) (radius * 2) + 2);
        width = radius * FroggumApplication.settings.get_double ("line-thickness");
        var motion_controller = new Gtk.EventControllerMotion ();
        add_controller (motion_controller);
        motion_controller.motion.connect ((x, y) => {
            var offset = (get_height () - width) / 2.0;
            if (y > offset + 1 + margin_top && y < offset + 1 + margin_top + width) {
                if (!hovering) {
                    hovering = true;
                    queue_draw ();
                }
            } else if (hovering) {
                hovering = false;
                queue_draw ();
            }
        });
    }

    public override void snapshot (Gtk.Snapshot snapshot) {
        var natural_offset = radius - width / 2.0;
        var offset = (get_height () - width) / 2.0;
        var circle = new Gsk.PathBuilder ();
        circle.add_circle ({(float) radius * 2 + 1, (float) (radius + 1 + offset - natural_offset)}, (float) radius);
        snapshot.append_fill (circle.to_path (), Gsk.FillRule.EVEN_ODD, {1, 0, 0, 1f});
        if (hovering) {
            snapshot.append_color ({0.15f, 0.85f, 0.95f, 1.0f}, {{0, (float) offset + 1 + margin_top}, {(float) get_width (), (float) width}});
        } else {
            snapshot.append_color ({1.0f, 0.0f, 0.0f, 1.0f}, {{0, (float) offset + 1 + margin_top}, {(float) get_width (), (float) width}});
        }
    }
}
