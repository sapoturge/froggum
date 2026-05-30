public class LinePreview : Gtk.Widget {
    public LinePreview () {}

    construct {
        FroggumApplication.settings.changed["line-thickness"].connect (() => queue_draw ());
        FroggumApplication.settings.changed["handle-radius"].connect (() => {
            var size = FroggumApplication.settings.get_double ("handle-radius");
            set_size_request ((int) (size * 4) + 2, (int) (size * 2) + 2);
            queue_draw ();
        });
        var size = FroggumApplication.settings.get_double ("handle-radius");
        set_size_request ((int) (size * 4) + 2, (int) (size * 2) + 2);
    }

    public override void snapshot (Gtk.Snapshot snapshot) {
        var radius = FroggumApplication.settings.get_double ("handle-radius");
        var width = radius * FroggumApplication.settings.get_double ("line-thickness");
        var natural_offset = radius - width / 2.0;
        var offset = (get_height () - width) / 2.0;
        var circle = new Gsk.PathBuilder ();
        circle.add_circle ({(float) radius * 2 + 1, (float) (radius + 1 + offset - natural_offset)}, (float) radius);
        snapshot.append_fill (circle.to_path (), Gsk.FillRule.EVEN_ODD, {1, 0, 0, 1f});
        snapshot.append_color ({0.15f, 0.85f, 0.95f, 1.0f}, {{0, (float) offset + 1 + margin_top}, {(float) get_width (), (float) width}});
    }
}
