public class Transform : Object, Undoable {
    public double translate_x { get; set; }
    public double translate_y { get; set; }
    public double scale_x { get; set; }
    public double scale_y { get; set; }
    public double angle { get; set; }
    public double skew { get; set; }

    private Point last_translate;
    private Point last_scale;
    private double last_angle;
    private double last_skew;

    public double width;
    public double height;

    private Cairo.Matrix matrix;

    public signal void update ();

    public Point center {
        get {
            Point point = {width/2, height/2};
            matrix.transform_point (ref point.x, ref point.y);
            return point;
        }

        set {
            Point old = center;
            translate_x += value.x - old.x;
            translate_y += value.y - old.y;
            update_matrix ();
            update ();
        }
    }

    public Point top_left {
        get {
            return { translate_x, translate_y };
        }
        set {
            var left = top_left;
            var right = top_right;
            var bottom = bottom_left;

            if ((value.x == right.x && value.y == right.y) || (value.x == bottom.x && value.y == bottom.y)) {
                return;
            }

            var dx = right.x - left.x;
            var dy = right.y - left.y;

            var scale = (dx * (value.x - left.x) + dy * (value.y - left.y)) / (dx * dx + dy * dy);

            Point a = { left.x + scale * dx, left.y + scale * dy };

            var ae = a.dist (value);

            // Use a determinant to determine whether the movement was up or down
            var side = (right.x - left.x) * (value.y - left.y) - (right.y - left.y) * (value.x - left.x);

            if (side < 0) {
                ae = -ae;
            }

            if (scale_x < 0) {
                ae = -ae;
            }

            var new_scale_y = scale_y - ae / height;
            
            var aa = a.dist (left);

            side = (bottom.x - left.x) * (value.y - left.y) - (bottom.y - left.y) * (value.x - left.x);

            if (side > 0) {
                aa = -aa;
            }

            if (scale_y < 0) {
                aa = -aa;
            }
            
            var new_scale_x = scale_x - (aa - ae * skew) / width;

            if (new_scale_x == 0 || new_scale_y == 0) {
                return;
            }

            scale_x = new_scale_x;
            scale_y = new_scale_y;

            translate_x = value.x;
            translate_y = value.y;
            update_matrix ();
            update ();
        }
    }

    public Point top_right {
        get {
            Point point = {width, 0};
            matrix.transform_point (ref point.x, ref point.y);
            return point;
        }

        set {
            var right = top_right;
            var left = top_left;
            var bottom = bottom_right;

            if ((value.x == left.x && value.y == left.y) || (value.x == bottom.x && value.y == bottom.y)) {
                return;
            }

            var dx = left.x - right.x;
            var dy = left.y - right.y;

            var scale = (dx * (value.x - right.x) + dy * (value.y - right.y)) / (dx * dx + dy * dy);

            Point a = { right.x + scale * dx, right.y + scale * dy };

            var ae = a.dist (value);

            // Use a determinant to determine whether the movement was up or down
            var side = (left.x - right.x) * (value.y - right.y) - (left.y - right.y) * (value.x - right.x);

            if (side > 0) {
                ae = -ae;
            }

            if (scale_x < 0) {
                ae = -ae;
            }

            var new_scale_y = scale_y - ae / height;
            
            var aa = a.dist (right);

            side = (bottom.x - right.x) * (value.y - right.y) - (bottom.y - right.y) * (value.x - right.x);

            if (side < 0) {
                aa = -aa;
            }

            if (scale_y < 0) {
                aa = -aa;
            }
            
            var new_scale_x = scale_x - (aa + ae * skew) / width;

            if (new_scale_x == 0 || new_scale_y == 0) {
                return;
            }

            // Calculate the transform by finding the unskewed point on
            // the top and finding the difference.

            scale = new_scale_x / scale_x;
            a = { left.x - scale * dx, left.y - scale * dy };
            translate_x += value.x - a.x;
            translate_y += value.y - a.y;

            scale_x = new_scale_x;
            scale_y = new_scale_y;
            update_matrix ();
            update ();
        }
    }

    public Point bottom_left {
        get {
            Point point = {0, height};
            matrix.transform_point (ref point.x, ref point.y);
            return point;
        }

        set {
            var left = bottom_left;
            var right = bottom_right;
            var top = top_left;

            if ((value.x == right.x && value.y == right.y) || (value.x == top.x && value.y == top.y)) {
                return;
            }

            var dx = right.x - left.x;
            var dy = right.y - left.y;

            var scale = (dx * (value.x - left.x) + dy * (value.y - left.y)) / (dx * dx + dy * dy);

            Point a = { left.x + scale * dx, left.y + scale * dy };

            var ae = a.dist (value);

            // Use a determinant to determine whether the movement was up or down
            var side = (right.x - left.x) * (value.y - left.y) - (right.y - left.y) * (value.x - left.x);

            if (side > 0) {
                ae = -ae;
            }

            if (scale_x < 0) {
                ae = -ae;
            }

            var new_scale_y = scale_y - ae / height;
            
            var aa = a.dist (left);

            side = (top.x - left.x) * (value.y - left.y) - (top.y - left.y) * (value.x - left.x);

            if (side < 0) {
                aa = -aa;
            }

            if (scale_y < 0) {
                aa = -aa;
            }
            
            var new_scale_x = scale_x - (aa + ae * skew) / width;

            if (new_scale_x == 0 || new_scale_y == 0) {
                return;
            }

            scale_x = new_scale_x;
            scale_y = new_scale_y;

            translate_x = top.x + scale * dx;
            translate_y = top.y + scale * dy;

            update_matrix ();
            update ();
        }
    }

    public Point bottom_right {
        get {
            Point point = {width, height};
            matrix.transform_point (ref point.x, ref point.y);
            return point;
        }

        set {
            var right = bottom_right;
            var left = bottom_left;
            var top = top_right;

            if ((value.x == left.x && value.y == left.y) || (value.x == top.x && value.y == top.y)) {
                return;
            }

            var dx = left.x - right.x;
            var dy = left.y - right.y;

            var scale = (dx * (value.x - right.x) + dy * (value.y - right.y)) / (dx * dx + dy * dy);

            Point a = { right.x + scale * dx, right.y + scale * dy };

            var ae = a.dist (value);

            // Use a determinant to determine whether the movement was up or down
            var side = (left.x - right.x) * (value.y - right.y) - (left.y - right.y) * (value.x - right.x);

            if (side < 0) {
                ae = -ae;
            }

            if (scale_x < 0) {
                ae = -ae;
            }

            var new_scale_y = scale_y - ae / height;
            
            var aa = a.dist (right);

            side = (top.x - right.x) * (value.y - right.y) - (top.y - right.y) * (value.x - right.x);

            if (side > 0) {
                aa = -aa;
            }

            if (scale_y < 0) {
                aa = -aa;
            }
            
            var new_scale_x = scale_x - (aa - ae * skew) / width;

            if (new_scale_x == 0 || new_scale_y == 0) {
                return;
            }

            scale_x = new_scale_x;
            scale_y = new_scale_y;
            update_matrix ();
            update ();
        }
    }

    public Point rotator {
        get {
            return {center.x + Math.sin (angle) * ((height * scale_y / 2).abs () + 5),
                    center.y - Math.cos (angle) * ((height * scale_y / 2).abs () + 5)};
        }
        set {
            var c = center;
            angle = Math.atan2 (value.x - c.x, c.y - value.y);

            update_matrix ();

            // Setting the center property automatically updates the translation
            center = c;
        }
    }

    public Point skewer {
        get {
            Point point = { width / 2, 3 * height / 4 };
            matrix.transform_point (ref point.x, ref point.y);
            return point;
        }
        set {
            var c = center;
            skew = Math.tan (angle - Math.atan2 (value.x - c.x, c.y - value.y));

            update_matrix ();

            // Setting the center property automatically updates the translation
            center = c;
        }
    }

    public Transform.identity () {
        translate_x = 0;
        translate_y = 0;
        scale_x = 1;
        scale_y = 1;
        angle = 0;
        skew = 0;

        matrix = Cairo.Matrix.identity ();

        notify.connect (() => {
            update_matrix ();
            update ();
        });
    }

    public Transform.from_string (string? description) {
        translate_x = 0;
        translate_y = 0;
        scale_x = 1;
        scale_y = 1;
        angle = 0;
        skew = 0;
        matrix = Cairo.Matrix.identity ();
        if (description != null) {
            var parser = new Parser (description);
            while (!parser.empty ()) {
                switch (parser.get_keyword ()) {
                    case Keyword.MATRIX:
                        var new_matrix = Cairo.Matrix.identity ();
                        parser.match ("(");
                        parser.get_double (out new_matrix.xx);
                        parser.match (",");
                        parser.get_double (out new_matrix.yx);
                        parser.match (",");
                        parser.get_double (out new_matrix.xy);
                        parser.match (",");
                        parser.get_double (out new_matrix.yy);
                        parser.match (",");
                        parser.get_double (out new_matrix.x0);
                        parser.match (",");
                        parser.get_double (out new_matrix.y0);
                        parser.match (")");
                        matrix.multiply (matrix, new_matrix);
                        break;
                    case Keyword.TRANSLATE:
                        parser.match ("(");
                        double translate_x;
                        parser.get_double (out translate_x);
                        double translate_y = 0.0;
                        if (!parser.match (")")) {
                            parser.match (",");
                            parser.get_double (out translate_y);
                            parser.match (")");
                        }
                        matrix.translate (translate_x, translate_y);
                        break;
                    case Keyword.ROTATE:
                        parser.match ("(");
                        double local_angle;
                        parser.get_double (out local_angle);
                        double cx = 0;
                        double cy = 0;
                        if (!parser.match (")")) {
                            parser.match (",");
                            parser.get_double (out cx);
                            parser.match (",");
                            parser.get_double (out cy);
                            parser.match (")");
                        }
               
                        matrix.translate (cx, cy);
                        matrix.rotate (local_angle * Math.PI / 180.0);
                        matrix.translate (-cx, -cy);
                        break;
                    case Keyword.SCALE:
                        parser.match ("(");
                        double sx;
                        parser.get_double (out sx);
                        var sy = sx;
                        if (!parser.match (")")) {
                            parser.match (",");
                            parser.get_double (out sy);
                            parser.match (")");
                        }
 
                        if (sx == 0) { sx = 1; }
                        if (sy == 0) { sy = 1; }
                        matrix.scale (sx, sy);
                        break;
                    case Keyword.SKEW_X:
                        parser.match ("(");
                        var new_mat = Cairo.Matrix.identity ();
                        var local_angle = 0.0;
                        parser.get_double (out local_angle);
                        new_mat.xy = Math.tan (local_angle * Math.PI / 180.0);
                        parser.match (")");
                        matrix.multiply (new_mat, matrix);
                        break;
                    case Keyword.SKEW_Y:
                        parser.match ("(");
                        var new_mat = Cairo.Matrix.identity ();
                        var angle = 0.0;
                        parser.get_double (out angle);
                        new_mat.yx = Math.tan (angle * Math.PI / 180.0);
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

            translate_x = matrix.x0;
            translate_y = matrix.y0;
            
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
            
            scale_x = Math.sqrt (matrix.xx * matrix.xx + matrix.yx * matrix.yx);
            this.angle = Math.atan2 (matrix.yx, matrix.xx);
            // I really hope my math is right on these.
            skew = (matrix.xy + matrix.yx * matrix.yy / matrix.xx) / (matrix.xx + matrix.yx * matrix.yx / matrix.xx);
            scale_y = (matrix.yy - matrix.yx * matrix.xy / matrix.xx) / (matrix.yx * matrix.yx / (scale_x * matrix.xx) + matrix.xx / scale_x);
        }

        notify.connect (() => {
            update_matrix ();
            update ();
        });
    }

    public bool is_identity () {
        return (translate_x == 0 && translate_y == 0
             && scale_x == 1 && scale_y == 1
             && angle == 0
             && skew == 0);
    }

    private void update_matrix () {
        matrix = Cairo.Matrix.identity ();
        matrix.translate (translate_x, translate_y);
        matrix.rotate (angle);
        var skew_mat = Cairo.Matrix.identity ();
        skew_mat.xy = skew;
        matrix.multiply (skew_mat, matrix);
        matrix.scale (scale_x, scale_y);
    }

    public void begin (string prop) {
        last_translate = {translate_x, translate_y};
        last_scale = {scale_x, scale_y};
        last_angle = angle;
        last_skew = skew;
    }

    public void finish (string prop) {
        var command = new Command ();
        switch (prop) {
            case "center":
                command.add_value (this, "translate_x", translate_x, last_translate.x);
                command.add_value (this, "translate_y", translate_y, last_translate.y);
                break;
            case "top_left":
            case "bottom_left":
            case "top_right":
                command.add_value (this, "translate_x", translate_x, last_translate.x);
                command.add_value (this, "translate_y", translate_y, last_translate.y);
                command.add_value (this, "scale_x", scale_x, last_scale.x);
                command.add_value (this, "scale_y", scale_y, last_scale.y);
                break;
            case "bottom_right":
                command.add_value (this, "scale_x", scale_x, last_scale.x);
                command.add_value (this, "scale_y", scale_y, last_scale.y);
                break;
            case "rotator":
                command.add_value (this, "translate_x", translate_x, last_translate.x);
                command.add_value (this, "translate_y", translate_y, last_translate.y);
                command.add_value (this, "angle", angle, last_angle);
                break;
            case "skewer":
                command.add_value (this, "translate_x", translate_x, last_translate.x);
                command.add_value (this, "translate_y", translate_y, last_translate.y);
                command.add_value (this, "skew", skew, last_skew);
                break;
        }

        add_command (command);
    }

    public void cancel (string prop) {
        translate_x = last_translate.x;
        translate_y = last_translate.y;
        scale_x = last_scale.x;
        scale_y = last_scale.y;
        skew = last_skew;
        angle = last_angle;
    }

    public void apply (Cairo.Context cr) {
        cr.save ();
        cr.translate (translate_x, translate_y);
        cr.rotate (angle);
        cr.transform (Cairo.Matrix (1, 0, skew, 1, 0, 0));
        cr.scale (scale_x, scale_y);
    }

    public string? to_string () {
        string[] pieces = {};

        if (translate_x != 0 || translate_y != 0) {
            pieces += "translate(%f,%f)".printf (translate_x, translate_y);
        }

        if (angle != 0) {
            pieces += "rotate(%f)".printf (angle * 180 / Math.PI);
        }

        if (skew != 0) {
            pieces += "skewX(%f)".printf (Math.atan (skew) * 180 / Math.PI);
        }

        if (scale_x != 1 || scale_y != 1) {
            pieces += "scale(%f,%f)".printf (scale_x, scale_y);
        }

        if (pieces.length == 0) {
            return null;
        } else {
            return string.joinv (null, pieces);
        }
    }

    public void draw_controls (Cairo.Context cr, double zoom) {
        cr.arc (center.x, center.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (top_right.x, top_right.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (top_left.x, top_left.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (bottom_right.x, bottom_right.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (bottom_left.x, bottom_left.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (rotator.x, rotator.y, 6 / zoom, 0, Math.PI * 2);
        cr.new_sub_path ();
        cr.arc (skewer.x, skewer.y, 6 / zoom, 0, Math.PI * 2);
        cr.set_source_rgb (0, 0, 1);
        cr.fill ();

        cr.set_line_width (1 / zoom);
        cr.move_to (top_left.x, top_left.y);
        cr.line_to (top_right.x, top_right.y);
        cr.line_to (bottom_right.x, bottom_right.y);
        cr.line_to (bottom_left.x, bottom_left.y);
        cr.close_path ();
        cr.stroke ();

        cr.move_to (rotator.x, rotator.y);
        cr.line_to (center.x, center.y);
        cr.line_to (skewer.x, skewer.y);
        cr.stroke ();
    }

    public bool check_controls (double x, double y, double tolerance, out Handle? handle) {
        if ((center.x - x).abs () <= tolerance && (center.y - y).abs () <= tolerance) {
            handle = new BaseHandle(this, "center", new Gee.ArrayList<ContextOption> ());
            return true;
        }

        if ((top_left.x - x).abs () <= tolerance && (top_left.y - y).abs () <= tolerance) {
            handle = new BaseHandle(this, "top_left", new Gee.ArrayList<ContextOption> ());
            return true;
        }

        if ((top_right.x - x).abs () <= tolerance && (top_right.y - y).abs () <= tolerance) {
            handle = new BaseHandle(this, "top_right", new Gee.ArrayList<ContextOption> ());
            return true;
        }

        if ((bottom_left.x - x).abs () <= tolerance && (bottom_left.y - y).abs () <= tolerance) {
            handle = new BaseHandle(this, "bottom_left", new Gee.ArrayList<ContextOption> ());
            return true;
        }

        if ((bottom_right.x - x).abs () <= tolerance && (bottom_right.y - y).abs () <= tolerance) {
            handle = new BaseHandle(this, "bottom_right", new Gee.ArrayList<ContextOption> ());
            return true;
        }

        if ((rotator.x - x).abs () <= tolerance && (rotator.y - y).abs () <= tolerance) {
            handle = new BaseHandle(this, "rotator", new Gee.ArrayList<ContextOption> ());
            return true;
        }

        if ((skewer.x - x).abs () <= tolerance && (skewer.y - y).abs () <= tolerance) {
            handle = new BaseHandle(this, "skewer", new Gee.ArrayList<ContextOption> ());
            return true;
        }

        handle = null;
        return false;
    }

    public void update_point (double x, double y, out double new_x, out double new_y) {
        var inverted = matrix;
        inverted.invert();
        inverted.transform_point (ref x, ref y);
        new_x = x;
        new_y = y;
    }

    public void apply_point (double x, double y, out double new_x, out double new_y) {
        matrix.transform_point (ref x, ref y);
        new_x = x;
        new_y = y;
    }

    public void update_distance (double dist, out double new_dist) {
        new_dist = dist;
        matrix.transform_distance (ref dist, ref new_dist);
        new_dist = Math.sqrt ((dist * dist + new_dist * new_dist) / 2);
    }
}
