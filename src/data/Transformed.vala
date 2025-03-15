public interface Transformed: Object {
    public abstract Transform transform { get; set; }

    public signal void set_size (double width, double height) {
        transform.width = width;
        transform.height = height;
    }

    public signal void apply_transform (Transform inner, Element? element);
}
