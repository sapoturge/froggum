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
             var inner_layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
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

             var standard_grid = new Gtk.Grid ();
             standard_grid.row_spacing = 4;
             standard_grid.column_spacing = 4;
             standard_grid.attach (n16, 0, 0, 1, 1);
             standard_grid.attach (n24, 1, 0, 1, 1);
             standard_grid.attach (n32, 2, 0, 1, 1);
             standard_grid.attach (n48, 0, 1, 1, 1);
             standard_grid.attach (n64, 1, 1, 1, 1);
             standard_grid.attach (n128, 2, 1, 1, 1);
             standard_grid.column_homogeneous = true;

             var custom_width = new Gtk.SpinButton.with_range (1, 2048, 1);
             var custom_height = new Gtk.SpinButton.with_range (1, 2018, 1);

             var ncustom = new Gtk.Button ();
             ncustom.label = "Custom:";
             ncustom.clicked.connect (() => {
                 new_image ((int) custom_width.value, (int) custom_height.value, tab);
             });

             var custom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
             custom_box.pack_start (ncustom, true, true);
             custom_box.pack_start (new Gtk.Label("Width:"), false, false);
             custom_box.pack_start (custom_width, false, false);
             custom_box.pack_start (new Gtk.Label ("Height:"), false, false);
             custom_box.pack_start (custom_height, false, false);

             var new_side = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);
             new_side.pack_start (title, false, false);
             new_side.pack_start (standard_grid, false, false);
             new_side.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false);
             new_side.pack_start (custom_box, false, false);

             var open_button = new Gtk.Button ();
             open_button.label = "Open";

             var open_side = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
             open_side.pack_start (open_button);
             open_side.valign = Gtk.Align.CENTER;

             inner_layout.pack_start (new_side, false, false);
             inner_layout.pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL), false, false);
             inner_layout.pack_start (open_side, false, false);

             inner_layout.halign = Gtk.Align.CENTER;
             inner_layout.valign = Gtk.Align.CENTER;

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
