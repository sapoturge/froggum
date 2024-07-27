public class PatternSegment : Segment {
    private Pattern parent;
    private double offset;

    public PatternSegment (Pattern parent, double offset) {
        this.parent = parent;
        this.offset = offset;
    }

    public override Gee.List<ContextOption> options () {
        return new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.action (_("Add Stop"), () => {
                var stop = new Stop (offset, parent.rgba);
                parent.add_stop (stop);
            })
        });
    }


    // This has no properties to save right now
    public override void begin (string prop) {}
    public override void finish (string prop) {}
    public override void cancel (string prop) {}
}
