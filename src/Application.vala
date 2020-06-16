public class SvgApp : Gtk.Application {
    public SvgApp () {
        Object (
            application_id: "com.github.sapoturge.svg_editor",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this);
        main_window.title = "Froggum";

        var header = new Gtk.HeaderBar ();
        header.decoration_layout = "icon:minimize,maximize,close";
        header.show_close_button = true;
        header.title = "Froggum";
        main_window.set_titlebar (header);

        var layout = new Gtk.Notebook ();
        var path = new Path ({
            new MoveSegment (1, 1),
            new LineSegment (15, 1),
            new LineSegment (15, 15),
            new LineSegment (1, 15),
            new ClosePathSegment ()
        }, {0.3, 0.3, 0.3, 1});
        var image = new Image ("Untitled", 16, 16, {path});
        var editor = new EditorView (image);
        editor.create ();
        editor.expand = true;
        layout.expand = true;

        layout.append_page (editor, new Gtk.Label(image.name));
        main_window.add (layout);
        main_window.show_all();
    }

    public static int main (string[] args) {
        var app = new SvgApp ();
        return app.run (args);
    }
}
