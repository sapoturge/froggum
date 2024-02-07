public class StatusBar : Gtk.Box {
    public Handle? handle {
        set { }
    }

    construct {
        var label = new Gtk.Label (_("No handle selected."));
        append (label);
        hexpand = true;
        vexpand = false;
    }
}
