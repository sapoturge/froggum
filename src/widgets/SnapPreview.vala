public class SnapPreview : Gtk.Widget {
    private double snap_distance;
    private double point_x;
    private double point_y;
    private bool draw_point;

    private const Gdk.RGBA SNAP_COLOR = {0.55f, 0.35f, 0.75f, 1.0f};
    private const Gdk.RGBA GRID_COLOR = {0.2f, 0.2f, 0.2f, 0.5f};
    private const float LINE_WIDTH = 2.0f;

    public SnapPreview () {}

    construct {
        FroggumApplication.settings.changed["snap-tolerance"].connect (() => {
            snap_distance = FroggumApplication.settings.get_double ("snap-tolerance");
            queue_draw ();
        });
        snap_distance = FroggumApplication.settings.get_double ("snap-tolerance");

        var motion_controller = new Gtk.EventControllerMotion ();
        add_controller (motion_controller);
        motion_controller.enter.connect ((x, y) => {
            draw_point = true;
            point_x = snap (x);
            point_y = snap (y);
            queue_draw ();
        });
        motion_controller.leave.connect (() => {
            draw_point = false;
            queue_draw ();
        });
        motion_controller.motion.connect ((x, y) => {
            point_x = snap (x - get_width () / 2) + get_width () / 2;
            point_y = snap (y - get_height () / 2) + get_height () / 2;
            queue_draw ();
        });

        set_size_request (80, 80);
    }

    private double snap (double val) {
        if (val.abs () < snap_distance / 2.0) {
            return 0.0;
        }

        return val;
    }

    public override void snapshot (Gtk.Snapshot snapshot) {
        var height = get_height ();
        var width = get_width ();
        var vertical = (width - LINE_WIDTH) / 2.0;
        var horizontal = (height - LINE_WIDTH) / 2.0;
        snapshot.append_color (SNAP_COLOR, {{0, (float) (horizontal - snap_distance / 2.0)}, {(float) width, (float) (LINE_WIDTH + snap_distance)}});
        snapshot.append_color (SNAP_COLOR, {{(float) (vertical - snap_distance / 2.0), 0}, {(float) (LINE_WIDTH + snap_distance), (float) height}});
        snapshot.append_color (GRID_COLOR, {{0, (float) horizontal}, {(float) width, LINE_WIDTH}});
        snapshot.append_color (GRID_COLOR, {{(float) vertical, 0}, {LINE_WIDTH, (float) height}});
        if (draw_point) {
            var circle = new Gsk.PathBuilder ();
            circle.add_circle ({(float) point_x, (float) point_y}, 15);
            snapshot.append_fill (circle.to_path (), Gsk.FillRule.EVEN_ODD, {1, 0, 0, 1f});
        }
    }
}
