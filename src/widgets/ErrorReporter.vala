public interface ErrorReporter : Gtk.Widget {
    public abstract void add_error (Error err);
}
