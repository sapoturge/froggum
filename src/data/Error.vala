public class Error : GLib.Object {
    public ErrorKind kind { get; construct; }
    public string detail { get; construct; }
    public string full_message { get; construct; }
    public string default_value { get; construct; }
    public Severity severity {
        get {
            return error_severity (kind);
        }
    }

    public Error (ErrorKind kind, string detail, string full, string default) {
        Object (kind: kind, detail: detail, full_message: full, default_value: default);
    }

    public Error.glib_error(GLib.Error error) {
        this (ErrorKind.INTERNAL_ERROR, error.code.to_string (), "GLib Error encountered: %s\n".printf (error.message), "");
    }

    public Error.unknown_element (string element, string parent) {
        this (ErrorKind.UNKNOWN_ELEMENT, element, "Unexpected element encountered.\nElement name: '%s'\nParent: '%s'\n".printf (element, parent), "");
    }

    public Error.missing_property (string element, string property, string default) {
        this (ErrorKind.MISSING_PROPERTY, "%s.%s".printf (element, property), "Required attribute missing.\nElement: %s\nAttribute: %s\nApplied default: %s\n".printf (element, property, default), default);
    }

    public Error.unknown_attribute (string element, string property, string value) {
        this (ErrorKind.UNKNOWN_PROPERTY, "%s.%s".printf (element, property), "This attribute is not supported by Froggum.\nElement: %s\nAttribute: %s\nValue: %s\n".printf (element, property, value), "");
    }

    public Error.invalid_property (string element, string property, string value, string default) {
        this (ErrorKind.INVALID_PROPERTY, "%s.%s".printf (element, property), "The given value for this attribute is not supported by Froggum\nElement: %s\nAttribute: %s\nValue: %s\nApplied default: %s\n".printf (element, property, value, default), default);
    }

    public bool has_default () {
        switch (kind) {
        case INTERNAL_ERROR:
        case CANT_READ:
        case CANT_WRITE:
        case INVALID_SVG:
        case UNKNOWN_ELEMENT:
        case UNKNOWN_PROPERTY:
            return false;
        case INVALID_PROPERTY:
        case MISSING_PROPERTY:
            return true;
        default:
            return false;
        }
    }

    public bool is_delete_element () {
        return kind == UNKNOWN_ELEMENT;
    }

    public bool is_delete_attribute () {
        return kind == UNKNOWN_PROPERTY;
    }

    public bool can_try_again () {
        return kind == CANT_WRITE || kind == CANT_READ;
    }

    public DefaultAction default_action () {
        switch (kind) {
        case INTERNAL_ERROR:
            return DefaultAction.OTHER;
        case CANT_WRITE:
            return DefaultAction.TRY_AGAIN;
        case CANT_READ:
        case INVALID_SVG:
        case UNKNOWN_ELEMENT:
        case UNKNOWN_PROPERTY:
        case INVALID_PROPERTY:
        case MISSING_PROPERTY:
            return DefaultAction.CREATE_NEW;
        default:
            return DefaultAction.CREATE_NEW;
        }
    }
}

public enum DefaultAction {
    CREATE_NEW,
    TRY_AGAIN,
    SAVE_NEW,
    OTHER,
}

public enum ErrorKind {
    INTERNAL_ERROR,
    CANT_READ,
    CANT_WRITE,
    INVALID_SVG,
    UNKNOWN_ELEMENT,
    UNKNOWN_PROPERTY,
    INVALID_PROPERTY,
    MISSING_PROPERTY,
}

public enum Severity {
    WARNING,
    ERROR,
}

public Severity error_severity (ErrorKind kind) {
    switch (kind) {
    case INTERNAL_ERROR:
        return Severity.ERROR;
    case CANT_READ:
        return Severity.ERROR;
    case CANT_WRITE:
        return Severity.ERROR;
    case INVALID_SVG:
        return Severity.ERROR;
    case INVALID_PROPERTY:
        return Severity.ERROR;
    case MISSING_PROPERTY:
        return Severity.ERROR;
    case UNKNOWN_ELEMENT:
        return Severity.WARNING;
    case UNKNOWN_PROPERTY:
        return Severity.WARNING;
    default:
        return Severity.ERROR;
    }
}

