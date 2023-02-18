public class LinearSegment : Segment {
    public override Gee.List<ContextOption> options () {
        return new Gee.ArrayList<ContextOption> ();
    }

    public override void begin (string prop, Value? value = 0) {
    }

    public override void finish (string prop) {
    }
}
