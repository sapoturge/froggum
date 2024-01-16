public class TransformedHandle : Handle {
    private Handle base;
    private Transform transform;

    public override Point point {
        get {
            Point basis = base.point;
            Point new_point = {};
            transform.update_point (basis.x, basis.y, out new_point.x, out new_point.y);
            return new_point;
        }
        set {
            Point new_point = {};
            transform.apply_point (value.x, value.y, out new_point.x, out new_point.y);
            base.point = new_point;
        }
    }

    public override Gee.List<ContextOption> options {
        get { return base.options; }
    }
}
