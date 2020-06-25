public class SvgApp : Gtk.Application {
    public SvgApp () {
        Object (
            application_id: "com.github.sapoturge.svg_editor",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this);
        main_window.title = "Untitled";

        // TODO: This should be made a setting.
        main_window.maximize ();
        main_window.set_default_size (640, 480);

        var header = new Gtk.HeaderBar ();
        header.decoration_layout = "icon:minimize,maximize,close";
        header.show_close_button = true;
        header.title = "Froggum";
        main_window.set_titlebar (header);

        var layout = new Granite.Widgets.DynamicNotebook ();
        var path = new Path ({
            new Segment.move (1.5, 1.5),
            new Segment.line (14.5, 1.5),
            new Segment.line (14.5, 14.5),
            new Segment.line (1.5, 14.5),
            new Segment.close ()
        }, {0.3, 0.3, 0.3, 1}, {0.1, 0.1, 0.1, 1});
        var image = new Image ("Untitled", 16, 16, {path});
        var editor = new EditorView (image);
        editor.expand = true;
        layout.expand = true;

        var tab = new Granite.Widgets.Tab (image.name, null, editor);
        layout.insert_tab (tab, 0);
        main_window.add (layout);
        main_window.show_all();
    }

    public static int main (string[] args) {
        var app = new SvgApp ();
        return app.run (args);
    }
}
