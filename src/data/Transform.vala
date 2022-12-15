public class Transform : Object, Undoable {
    public Point translate { get; set; }
    public Point scale { get; set; }
    public double angle { get; set; }
    public double skew { get; set; }

    private Point last_translate;
    private Point last_scale;
    private double last_angle;
    private double last_skew;

    private double width = 16;
    private double height = 16;

    public signal void update ();

    public Point center {
        get {
            var mat = Cairo.Matrix.identity ();
            mat.translate (translate.x, translate.y);
            mat.scale (scale.x, scale.y);
            mat.rotate (angle);
            var skew_mat = Cairo.Matrix.identity ();
            skew_mat.xy = skew;
            mat.multiply (skew_mat, mat);
            Point point = {width/2, height/2};
            mat.transform_point (ref point.x, ref point.y);
            return point;
        }

        set {
            Point old = center;
            Point new_point = { 0, 0 };
            new_point.x = translate.x + value.x - old.x;
            new_point.y = translate.y + value.y - old.y;
            translate = new_point;
            update ();
        }
    }

    public Point top_right { get; set; }
    public Point top_left { get; set; }
    public Point bottom_right { get; set; }
    public Point bottom_left { get; set; }
    public Point rotator { get; set; }
    public Point skew_block { get; set; }

    public Transform.identity () {
        this.translate = {0, 0};
        this.scale = {1, 1};
        this.angle = 0;
        this.skew = 0;
    }

    public Transform.from_string (string? description) {
        if (description == null) {
            translate = {0, 0};
            scale = {1, 1};
            angle = 0;
            skew = 0;
        } else {
            var matrix = Cairo.Matrix.identity ();
            var parser = new Parser (description);
            while (!parser.empty ()) {
                switch (parser.get_keyword ()) {
                    case Keyword.MATRIX:
                        var new_matrix = Cairo.Matrix.identity ();
                        parser.match ("(");
                        new_matrix.xx = parser.get_double ();
                        parser.match (",");
                        new_matrix.yx = parser.get_double ();
                        parser.match (",");
                        new_matrix.xy = parser.get_double ();
                        parser.match (",");
                        new_matrix.yy = parser.get_double ();
                        parser.match (",");
                        new_matrix.x0 = parser.get_double ();
                        parser.match (",");
                        new_matrix.y0 = parser.get_double ();
                        parser.match (")");
                        matrix.multiply (matrix, new_matrix);
                        break;
                    case Keyword.TRANSLATE:
                        parser.match ("(");
                        var translate_x = parser.get_double ();
                        var translate_y = 0.0;
                        if (!parser.match (")")) {
                            parser.match (",");
                            translate_y = parser.get_double ();
                            parser.match (")");
                        }
                        matrix.translate (translate_x, translate_y);
                        break;
                    case Keyword.ROTATE:
                        parser.match ("(");
                        var angle = parser.get_double ();
                        double cx = 0;
                        double cy = 0;
                        if (!parser.match (")")) {
                            parser.match (",");
                            cx = parser.get_double ();
                            parser.match (",");
                            cy = parser.get_double ();
                            parser.match (")");
                        }
               
                        matrix.translate (cx, cy);
                        matrix.rotate (angle);
                        matrix.translate (-cx, -cy);
                        break;
                    case Keyword.SCALE:
                        parser.match ("(");
                        var sx = parser.get_double ();
                        var sy = sx;
                        if (!parser.match (")")) {
                            parser.match (",");
                            sy = parser.get_double ();
                            parser.match (")");
                        }
 
                        matrix.scale (sx, sy);
                        break;
                    case Keyword.SKEW_X:
                        parser.match ("(");
                        var new_mat = Cairo.Matrix.identity ();
                        new_mat.xy = Math.tan (parser.get_double () * Math.PI / 180.0);
                        parser.match (")");
                        matrix.multiply (new_mat, matrix);
                        break;
                    case Keyword.SKEW_Y:
                        parser.match ("(");
                        var new_mat = Cairo.Matrix.identity ();
                        new_mat.yx = Math.tan (parser.get_double () * Math.PI / 180.0);
                        parser.match (")");
                        matrix.multiply (new_mat, matrix);
                        break;
                    default:
                        parser.error ("Unrecognised transform");
                        // Empties the buffer, ending the loop
                        parser.get_string ();
                        break;
                }
            }
            
            translate.x = matrix.x0;
            translate.y = matrix.y0;
            
            // The remaining matrix values are as follows:
            // 
            // +-              -+
            // | C*S  C*S*K-N*s |
            // | N*S  N*S*K+C*s |
            // +-              -+
            // 
            // Where
            //    C = cos(angle)
            //    N = sin(angle)
            //    S = scale in X direction
            //    s = scale in Y direction
            //    K = skew on X axis
            
            scale.x = Math.sqrt (matrix.xx * matrix.xx + matrix.yx * matrix.yx);
            angle = Math.atan2 (matrix.yx, matrix.xx);
            // I really hope my math is right on these.
            skew = (matrix.xy + matrix.yx * matrix.yy / matrix.xx) / (matrix.xx + matrix.yx * matrix.yx / matrix.xx);
            scale.y = (matrix.yy - matrix.yx * matrix.xy / matrix.xx) / (matrix.yx * matrix.yx / (scale.x * matrix.xx) + matrix.xx / scale.x);
        }
    }

    public override void begin (string prop, Value? initial_value = null) {
        last_translate = translate;
        last_scale = scale;
        last_angle = angle;
        last_skew = skew;
    }

    public override void finish (string prop) {
        var command = new Command ();
        switch (prop) {
            case "center":
                command.add_value (this, "translate", translate, last_translate);
                break;
        }

        add_command (command);
    }

    public void apply (Cairo.Context cr) {
        cr.save ();
        cr.translate (translate.x, translate.y);
        cr.scale (scale.x, scale.y);
        cr.rotate (angle);
        cr.transform (Cairo.Matrix (1, 0, skew, 1, 0, 0));
    }

    public string? to_string () {
        string[] pieces = {};

        if (translate.x != 0 || translate.y != 0) {
            pieces += "translate(%f,%f)".printf (translate.x, translate.y);
        }

        if (scale.x != 1 || scale.y != 1) {
            pieces += "scale(%f,%f)".printf (scale.x, scale.y);
        }

        if (angle != 0) {
            pieces += "rotate(%f)".printf (angle);
        }

        if (skew != 0) {
            pieces += "skewX(%f)".printf (Math.atan (skew) * 180 / Math.PI);
        }

        if (pieces.length == 0) {
            return null;
        } else {
            return string.joinv (null, pieces);
        }
    }

    public void draw_controls (Cairo.Context cr, double zoom) {
        cr.arc (width / 2, height / 2, 4 / zoom, 0, Math.PI * 2);
        cr.set_source_rgb (0, 0, 1);
        cr.fill ();
    }

    public bool check_controls (double x, double y, double tolerance, out Undoable obj, out string prop) {
        if ((center.x - x).abs () <= tolerance && (center.y - y).abs () <= tolerance) {
            obj = this;
            prop = "center";
            return true;
        }

        obj = null;
        prop = null;
        return false;
    }
}
