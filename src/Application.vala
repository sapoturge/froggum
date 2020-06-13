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
        main_window.show_all();
    }

    public static int main (string[] args) {
        var app = new SvgApp ();
        return app.run (args);
    }
}
