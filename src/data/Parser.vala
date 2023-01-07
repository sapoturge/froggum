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

    public bool get_int (out int value) {
        bool negative = match ("-");
        if (!get_digit (out value, 10, false)) {
            value = 0;
            return false;
        }
        int next_digit = 0;
        while (data != "" && get_digit (out next_digit, 10, false)) {
            value *= 10;
            value += next_digit;
        }

        if (negative) {
            value = -value;
        }

        return true;
    }

    public bool get_double (out double value) {
        double multiplier = 1;
        if (match ("-")) {
            multiplier = -1;
        }

        int base_val;
        var has_int_part = get_int (out base_val);
        value = base_val;
        var has_decimal_part = match (".", false);
        if (!(has_int_part || has_decimal_part)) {
            return false;
        }

        int next_digit = 0;
        while (data != "" && get_digit (out next_digit, 10, false)) {
            multiplier /= 10;
            value += multiplier * next_digit;
        }
        return true;
    }

    public bool get_digit (out int value, int num_base=10, bool strip = true) {
        if (strip) {
            data = data.strip ();
        }

        string digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        for (value = 0; value < num_base && value < digits.length; value++) {
            string digit_value = digits.substring (value, 1);
            if (match (digit_value, false) || match (digit_value.down (), false)) {
                return true;
            }
        }
        
        value = 0;
        return false;
    }

    public bool get_hex (out int value) {
        data = data.strip ();
        if (!get_digit (out value, 16)) {
            value = 0;
            return false;
        }

        int next_digit = 0;
        while (data != "" && get_digit (out next_digit, 16, false)) {
            value *= 16;
            value += next_digit;
        }

        return true;
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
