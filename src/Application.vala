public class SvgApp : Gtk.Application {
    public SvgApp () {
        Object (
            application_id: "com.github.FroggiesareFluffy.svg_editor",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this);
        main_window.title = "SVG Editor";
        var layout = new Gtk.Grid ();
        var path = new Path ({
            new MoveSegment (1, 1),
            new LineSegment (15, 1),
            new LineSegment (15, 15),
            new LineSegment (1, 15),
            new ClosePathSegment ()
        }, new Color(123, 123, 123, 255));
        var image = new Image (16, 16, {path});
        var editor = new EditorView (image);
        editor.create ();
        editor.expand = true;
        layout.expand = true;
        layout.attach (editor, 0, 0, 1, 1);
        main_window.add (layout);
        main_window.show_all();
    }

    public static int main (string[] args) {
        var app = new SvgApp ();
        return app.run (args);
    }
}
