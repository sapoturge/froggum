public class Transform : Object {
    private Point translate;
    private Point scale;
    private double angle;
    private double skew;

    public Transform.identity () {
        this.translate = {0, 0};
        this.scale = {1, 1};
        this.angle = 0;
        this.skew = 0;
    }
}
