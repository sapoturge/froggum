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

    private Segment? _segment;
    public override Segment? segment {
        get { return _segment; }
    }

    protected override BaseHandle core {
        get { return this; }
    }

    private Gee.List<ContextOption> _options;
    public override Gee.List<ContextOption> options {
        get {
            return _options;
        }
    }

    public BaseHandle (Undoable target, string property, Gee.List<ContextOption> options, Segment? segment) {
        this.target = target;
        this.property = property;
        this._options = options;
        this.target.notify.connect (() => updated ());
        this._segment = segment;
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

    public override void cancel (string prop) {
        if (prop == "point") {
            target.cancel (property);
        }
    }

    public void add_option (ContextOption option) {
        _options.add (option);
    }

    public override bool same_point (Handle handle) {
        return (target == handle.core.target && property == handle.core.property);
    }
}
