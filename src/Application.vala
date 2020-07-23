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

        layout.new_tab_requested.connect (() => {
             var inner_layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
             var tab = new Granite.Widgets.Tab ("New Image", null, inner_layout);

             var title = new Gtk.Label ("Create a new icon:");

             var n16 = new Gtk.Button ();
             n16.label = "16 x 16";
             n16.clicked.connect (() => {
                 new_image (16, 16, tab);
             });

             var n24 = new Gtk.Button ();
             n24.label = "24 x 24";
             n24.clicked.connect (() => {
                 new_image (24, 24, tab);
             });

             var n32 = new Gtk.Button ();
             n32.label = "32 x 32";
             n32.clicked.connect (() => {
                 new_image (32, 32, tab);
             });
 
             var n48 = new Gtk.Button ();
             n48.label = "48 \u00D7 48";
             n48.clicked.connect (() => {
                 new_image (48, 48, tab);
             });

             var n64 = new Gtk.Button ();
             n64.label = "64 \u00D7 64";
             n64.clicked.connect (() => {
                 new_image (64, 64, tab);
             });

             var n128 = new Gtk.Button ();
             n128.label = "128 \u00D7 128";
             n128.clicked.connect (() => {
                 new_image (128, 128, tab);
             });

             var ncustom = new Gtk.Button ();
             ncustom.label = "Custom";
             ncustom.clicked.connect (() => {
                 // TODO: Allow picking sizes.
                 new_image (50, 50, tab);
             });

             var grid = new Gtk.Grid ();
             grid.attach (title, 0, 0, 3, 1);
             grid.attach (n16, 0, 2, 1, 1);
             grid.attach (n24, 1, 2, 1, 1);
             grid.attach (n32, 2, 2, 1, 1);
             grid.attach (n48, 0, 3, 1, 1);
             grid.attach (n64, 1, 3, 1, 1);
             grid.attach (n128, 2, 3, 1, 1);
             grid.attach (ncustom, 0, 4, 3, 1);

             inner_layout.pack_start (grid, false, false);

             layout.insert_tab (tab, 0);
             layout.show_all ();
        });

        layout.expand = true;

        // TODO: Load previous session
        layout.new_tab_requested ();

        main_window.add (layout);
        main_window.show_all();
    }

    private void new_image (int width, int height, Granite.Widgets.Tab tab) {
        var path = new Path ({
            new Segment.line (width - 1.5, 1.5),
            new Segment.line (width - 1.5, height - 1.5),
            new Segment.line (1.5, height - 1.5),
            new Segment.line (1.5, 1.5)
        }, {0.3, 0.3, 0.3, 1}, {0.1, 0.1, 0.1, 1});
        var image = new Image ("Untitled", width, height, {path});
        var editor = new EditorView (image);
        editor.expand = true;

        tab.page = editor;
        tab.show_all ();
    }

    public static int main (string[] args) {
        var app = new SvgApp ();
        return app.run (args);
    }
}
