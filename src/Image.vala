public class Image {
    private int width;
    private int height;

    private Path[] paths;

    public Image (int width, int height, Path[] paths = {}) {
        this.width = width;
        this.height = height;
        this.paths = paths;
    }

    public void draw (Cairo.Context cr) {
        foreach (Path path in paths) {
            path.draw (cr);
        }
    }
}
