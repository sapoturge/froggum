public class TransformedHandle : Handle {
    private Handle base_handle;
    private Transform transform;
    public string name { get; private set; }

    public override Point point {
        get {
            Point basis = base_handle.point;
            Point new_point = {};
            transform.apply_point (basis.x, basis.y, out new_point.x, out new_point.y);
            return new_point;
        }
        set {
            Point new_point = {};
            transform.update_point (value.x, value.y, out new_point.x, out new_point.y);
            base_handle.point = new_point;
        }
    }

    public override Gee.List<ContextOption> options {
        get { return base_handle.options; }
    }

    public override void begin (string prop) {
        if (prop == "point") {
            base_handle.begin ("point");
        }
    }

    public override void finish (string prop) {
        if (prop == "point") {
            base_handle.finish ("point");
        }
    }

    public TransformedHandle (string name, Handle base_handle, Transform transform) {
        this.name = name;
        this.base_handle = base_handle;
        this.transform = transform;
    }
}
