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
    private int index;

    public Parser (string data) {
        this.data = data;
        this.index = 0;
        skip_whitespace ();
    }

    public void skip_whitespace () {
        unichar next_character;
        int next_index = index;
        while (data.get_next_char (ref next_index, out next_character)) {
            if (next_character.isspace ()) {
                index = next_index;
            } else {
                break;
            }
        }
    }

    public bool has_prefix (string prefix) {
        var check_index = index;
        unichar prefix_char, data_char;
        for (int i = 0; prefix.get_next_char (ref i, out prefix_char);) {
            if (!data.get_next_char (ref check_index, out data_char)) {
                return false;
            }

            if (prefix_char != data_char) {
                return false;
            }
        }

        return true;
    }

    public Keyword get_keyword () {
        skip_whitespace ();
        if (has_prefix ("translate")) {
            index += 9;
            return Keyword.TRANSLATE;
        } else if (has_prefix ("matrix")) {
            index += 6;
            return Keyword.MATRIX;
        } else if (has_prefix ("rotate")) {
            index += 6;
            return Keyword.ROTATE;
        } else if (has_prefix ("skewX")) {
            index += 5;
            return Keyword.SKEW_X;
        } else if (has_prefix ("skewY")) {
            index += 5;
            return Keyword.SKEW_Y;
        } else if (has_prefix ("scale")) {
            index += 5;
            return Keyword.SCALE;
        } else if (has_prefix ("rgba")) {
            index += 4;
            return Keyword.RGBA;
        } else if (has_prefix ("none")) {
            index += 4;
            return Keyword.NONE;
        } else if (has_prefix ("url")) {
            index += 3;
            return Keyword.URL;
        } else if (has_prefix ("rgb")) {
            index += 3;
            return Keyword.RGB;
        } else {
            return Keyword.NOT_FOUND;
        }
    }

    public bool match (string prefix, bool strip=true) {
        if (strip) {
            skip_whitespace ();
        }

        if (has_prefix (prefix)) {
            index += prefix.length;
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

    public bool get_float (out float value) {
        float multiplier = 1;
        if (match ("-")) {
            multiplier = -1;
        }

        int base_val;
        var has_int_part = get_int (out base_val);
        value = base_val * multiplier;
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

    public bool get_double (out double value) {
        double multiplier = 1;
        if (match ("-")) {
            multiplier = -1;
        }

        int base_val;
        var has_int_part = get_int (out base_val);
        value = base_val * multiplier;
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
            skip_whitespace ();
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
            var result = data.substring (index);
            index = data.length;
            return result;
        } else {
            var result = data.substring (index, length);
            index += length;
            return result;
        }
    }

    public Gdk.RGBA? get_color () {
        var rgba = Gdk.RGBA ();
        if (rgba.parse (data)) {
            // Assume the color was the entire data
            index = data.length;
            return rgba;
        } else {
            return null;
        }
    }

    public bool empty () {
        return index >= data.length;
    }

    public void error (string message) {
        stderr.printf ("Error: %s (text: %s)\n", message, data);
    }
}
