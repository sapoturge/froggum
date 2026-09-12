public class PatternSegment : Segment {
    private Pattern parent;
    private double offset;

    public PatternSegment (Pattern parent, double offset) {
        this.parent = parent;
        this.offset = offset;
    }

    public override Gee.List<ContextOption> options () {
        var pattern_type_options = new Gee.HashMap<string, int> ();
        pattern_type_options.set (_("Linear"), PatternType.LINEAR);
        pattern_type_options.set (_("Radial"), PatternType.RADIAL);
        return new Gee.ArrayList<ContextOption>.wrap (new ContextOption[]{
            new ContextOption.action (_("Add Stop"), () => {
                var stop = new Stop (offset, parent.rgba);
                parent.add_stop (stop);
            }),
            new ContextOption.action (_("Reverse Gradient"), () => {
                parent.reverse_gradient ();
            }),
            new ContextOption.options (_("Gradient Type"), parent, "pattern-type", pattern_type_options),
        });
    }


    // This has no properties to save right now
    public override void begin (string prop) {}
    public override void finish (string prop) {}
    public override void cancel (string prop) {}
}
