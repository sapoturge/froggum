public enum ContextOptionType {
    SEPARATOR,
    ACTION,
    TOGGLE,
    OPTIONS,
}

public class ContextOption : Object {
    public delegate void ActionCallback ();

    public ContextOptionType option_type { get; private set; }
    public string label { get; private set; }
    public Undoable target { get; private set; }
    public string prop { get; private set; }
    public Gee.Map<string, int> option_values { get; private set; }
    private ActionCallback? callback; // Apparently delegates can't be used as properties.

    public ContextOption.separator () {
        option_type = SEPARATOR;
    }

    public ContextOption.action (string label, owned ActionCallback callback) {
        option_type = ACTION;
        this.label = label;
        this.callback = (owned) callback;
    }

    public ContextOption.toggle (string label, Undoable obj, string prop) {
        option_type = TOGGLE;
        this.label = label;
        this.target = obj;
        this.prop = prop;
    }

    public ContextOption.options (string label, Undoable obj, string prop, Gee.Map<string, int> options) {
        option_type = OPTIONS;
        this.label = label;
        this.target = obj;
        this.prop = prop;
        this.option_values = options;
    }

    public void activate () {
        if (callback != null) {
            callback ();
        }
    }
}
