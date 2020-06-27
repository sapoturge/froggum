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
        header.decoration_layout = "close:maximize";
        header.show_close_button = true;
        header.title = "Froggum";
        
        var layout = new Granite.Widgets.DynamicNotebook ();

        var save_button = new Gtk.Button ();
        save_button.label = "Save As";
        save_button.clicked.connect (() => {
            var file_chooser = new Gtk.FileChooserNative ("Save As", main_window, Gtk.FileChooserAction.SAVE, null, null);
            file_chooser.set_current_name ("Untitled Image");
            var res = file_chooser.run ();
            if (res == Gtk.ResponseType.ACCEPT) {
                var tab = layout.current;
                var editor = tab.page;
                if (editor is EditorView) {
                    var file = File.new_for_path (file_chooser.get_filename ());
                    ((EditorView) editor).image.file = file;
                    tab.label = file.get_basename ();
                }
            }
        });

        header.pack_start (save_button);

        main_window.set_titlebar (header);

        var path = new Path ({
            new Segment.move (1.5, 1.5),
            new Segment.line (14.5, 1.5),
            new Segment.curve (8, 4, 8, 12, 14.5, 14.5),
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
