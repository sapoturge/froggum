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
}
