public class BaseHandle : Handle {
    private Undoable target;
    public string property { get; private set; }

    public override Point point {
        get {
            Point? value = {};
            target.get(property, ref value);
            return (!) value;
        }
        set {
            target.set(property, value);
        }
    }

    private Gee.List<ContextOption> _options;
    public override Gee.List<ContextOption> options {
        get {
            return _options;
        }
    }

    public BaseHandle (Undoable target, string property, Gee.List<ContextOption> options) {
        this.target = target;
        this.property = property;
        this._options = options;
    }

    public override void begin (string prop) {
        if (prop == "point") {
            target.begin (property);
        }
    }

    public override void finish (string prop) {
        if (prop == "point") {
            target.finish (property);
        }
    }

    public void add_option (ContextOption option) {
        _options.add (option);
    }
}
