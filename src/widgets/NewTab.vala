public class NewTab : Gtk.Box, ErrorReporter {
    private ErrorBar error_bar;

    public signal void new_image (int width, int height);
    public signal void open_image ();

    public NewTab () {}

    construct {
         error_bar = new ErrorBar ();
         error_bar.error = null;
         error_bar.resolve_error.connect (() => error_bar.error = null);

         var inner_layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);

         var title = new Gtk.Label (_("Create a new icon:"));

         var n16 = new Gtk.Button ();
         n16.label = _("16 \u00D7 16");
         n16.clicked.connect (() => {
             new_image (16, 16);
         });

         var n24 = new Gtk.Button ();
         n24.label = _("24 \u00D7 24");
         n24.clicked.connect (() => {
             new_image (24, 24);
         });

         var n32 = new Gtk.Button ();
         n32.label = _("32 \u00D7 32");
         n32.clicked.connect (() => {
             new_image (32, 32);
         });

         var n48 = new Gtk.Button ();
         n48.label = _("48 \u00D7 48");
         n48.clicked.connect (() => {
             new_image (48, 48);
         });

         var n64 = new Gtk.Button ();
         n64.label = _("64 \u00D7 64");
         n64.clicked.connect (() => {
             new_image (64, 64);
         });

         var n128 = new Gtk.Button ();
         n128.label = _("128 \u00D7 128");
         n128.clicked.connect (() => {
             new_image (128, 128);
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
         ncustom.label = _("Custom:");
         ncustom.clicked.connect (() => {
             new_image ((int) custom_width.value, (int) custom_height.value);
         });

         var custom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
         custom_box.append (ncustom);
         custom_box.append (new Gtk.Label("Width:"));
         custom_box.append (custom_width);
         custom_box.append (new Gtk.Label ("Height:"));
         custom_box.append (custom_height);

         var new_side = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);
         new_side.append (title);
         new_side.append (standard_grid);
         new_side.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
         new_side.append (custom_box);

         var open_button = new Gtk.Button ();
         open_button.label = _("Open");
         open_button.clicked.connect (() => {
             open_image ();
         });

         var open_side = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
         open_side.append (open_button);
         open_side.valign = Gtk.Align.CENTER;

         inner_layout.append (new_side);
         inner_layout.append (new Gtk.Separator (Gtk.Orientation.VERTICAL));
         inner_layout.append (open_side);

         inner_layout.halign = Gtk.Align.CENTER;
         inner_layout.valign = Gtk.Align.CENTER;
         inner_layout.hexpand = true;
         inner_layout.vexpand = true;

         append (error_bar);
         append (inner_layout);
         hexpand = true;
         vexpand = true;
         orientation = Gtk.Orientation.VERTICAL;
    }

    public void add_error (Error err) {
        error_bar.error = err;
    }
}
