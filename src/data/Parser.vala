public enum Keyword {
    TRANSLATE,
    MATRIX,
    ROTATE,
    SKEW_X,
    SKEW_Y,
    SCALE,
    NONE,
    RGBA,
    URL,
    RGB,
    NOT_FOUND = -1,
}

public class Parser : Object {
    private string data;

    public Parser (string data) {
        this.data = data;
    }

    public Keyword get_keyword () {
        data = data.strip ();
        if (data.has_prefix ("translate")) {
            data = data.substring (9);
            return Keyword.TRANSLATE;
        } else if (data.has_prefix ("matrix")) {
            data = data.substring (6);
            return Keyword.MATRIX;
        } else if (data.has_prefix ("rotate")) {
            data = data.substring (6);
            return Keyword.ROTATE;
        } else if (data.has_prefix ("skewX")) {
            data = data.substring (5);
            return Keyword.SKEW_X;
        } else if (data.has_prefix ("skewY")) {
            data = data.substring (5);
            return Keyword.SKEW_Y;
        } else if (data.has_prefix ("scale")) {
            data = data.substring (5);
            return Keyword.SCALE;
        } else if (data.has_prefix ("rgba")) {
            data = data.substring (4);
            return Keyword.RGBA;
        } else if (data.has_prefix ("none")) {
            data = data.substring (4);
            return Keyword.NONE;
        } else if (data.has_prefix ("url")) {
            data = data.substring (3);
            return Keyword.URL;
        } else if (data.has_prefix ("rgb")) {
            data = data.substring (3);
            return Keyword.RGB;
        } else {
            return Keyword.NOT_FOUND;
        }
    }

    public bool match (string prefix, bool strip=true) {
        if (strip) {
            data = data.strip ();
        }
        if (data.has_prefix (prefix)) {
            data = data.substring (prefix.length);
            return true;
        }
        return false;
    }

    public int get_int () {
        data = data.strip ();
        int value = 0;
        while (data != "") {
            if (data.has_prefix ("0")) {
                data = data.substring (1);
                value *= 10;
            } else if (data.has_prefix ("1")) {
                data = data.substring (1);
                value *= 10;
                value += 1;
            } else if (data.has_prefix ("2")) {
                data = data.substring (1);
                value *= 10;
                value += 2;
            } else if (data.has_prefix ("3")) {
                data = data.substring (1);
                value *= 10;
                value += 3;
            } else if (data.has_prefix ("4")) {
                data = data.substring (1);
                value *= 10;
                value += 4;
            } else if (data.has_prefix ("5")) {
                data = data.substring (1);
                value *= 10;
                value += 5;
            } else if (data.has_prefix ("6")) {
                data = data.substring (1);
                value *= 10;
                value += 6;
            } else if (data.has_prefix ("7")) {
                data = data.substring (1);
                value *= 10;
                value += 7;
            } else if (data.has_prefix ("8")) {
                data = data.substring (1);
                value *= 10;
                value += 8;
            } else if (data.has_prefix ("9")) {
                data = data.substring (1);
                value *= 10;
                value += 9;
            } else {
                return value;
            }
        }
        return value;
    }

    public double get_double () {
        double value = get_int ();
        match (".", false);
        double exponent = 0;
        while (data != "") {
            if (data.has_prefix ("0")) {
                data = data.substring (1);
                exponent -= 1;
            } else if (data.has_prefix ("1")) {
                data = data.substring (1);
                exponent -= 1;
                value += 1 * Math.exp10 (exponent);
            } else if (data.has_prefix ("2")) {
                data = data.substring (1);
                exponent -= 1;
                value += 2 * Math.exp10 (exponent);
            } else if (data.has_prefix ("3")) {
                data = data.substring (1);
                exponent -= 1;
                value += 3 * Math.exp10 (exponent);
            } else if (data.has_prefix ("4")) {
                data = data.substring (1);
                exponent -= 1;
                value += 4 * Math.exp10 (exponent);
            } else if (data.has_prefix ("5")) {
                data = data.substring (1);
                exponent -= 1;
                value += 5 * Math.exp10 (exponent);
            } else if (data.has_prefix ("6")) {
                data = data.substring (1);
                exponent -= 1;
                value += 6 * Math.exp10 (exponent);
            } else if (data.has_prefix ("7")) {
                data = data.substring (1);
                exponent -= 1;
                value += 7 * Math.exp10 (exponent);
            } else if (data.has_prefix ("8")) {
                data = data.substring (1);
                exponent -= 1;
                value += 8 * Math.exp10 (exponent);
            } else if (data.has_prefix ("9")) {
                data = data.substring (1);
                exponent -= 1;
                value += 9 * Math.exp10 (exponent);
            } else {
                return value;
            }
        }
        return value;
    }

    public int get_hex () {
        data = data.strip ();
        int value = 0;
        while (data != "") {
            if (match ("0", false)) {
                value *= 16;
            } else if (match ("1", false)) {
                value *= 16;
                value += 1;
            } else if (match ("2", false)) {
                value *= 16;
                value += 2;
            } else if (match ("3", false)) {
                value *= 16;
                value += 3;
            } else if (match ("4", false)) {
                value *= 16;
                value += 4;
            } else if (match ("5", false)) {
                value *= 16;
                value += 5;
            } else if (match ("6", false)) {
                value *= 16;
                value += 6;
            } else if (match ("7", false)) {
                value *= 16;
                value += 7;
            } else if (match ("8", false)) {
                value *= 16;
                value += 8;
            } else if (match ("9", false)) {
                value *= 16;
                value += 9;
            } else if (match ("a", false) || match ("A", false)) {
                value *= 16;
                value += 10;
            } else if (match ("b", false) || match ("B", false)) {
                value *= 16;
                value += 11;
            } else if (match ("c", false) || match ("C", false)) {
                value *= 16;
                value += 12;
            } else if (match ("d", false) || match ("D", false)) {
                value *= 16;
                value += 13;
            } else if (match ("e", false) || match ("E", false)) {
                value *= 16;
                value += 14;
            } else if (match ("f", false) || match ("F", false)) {
                value *= 16;
                value += 15;
            } else {
                return value;
            }
        }
        return value;
    }

    public string get_string (int length=0) {
        if (length <= 0) {
            var result = data;
            data = "";
            return result;
        } else {
            var result = data.substring (0, length);
            data = data.substring (length);
            return result;
        }
    }

    public bool empty () {
        return data.length == 0;
    }

    public void error (string message) {
        stderr.printf ("Error: %s (text: %s)\n", message, data);
    }
}
