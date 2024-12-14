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

    public Error.missing_property (string element, string property, string default) {
        this (ErrorKind.MISSING_PROPERTY, "%s.%s".printf (element, property), "Required attribute missing.\nElement: %s\nAttribute: %s\nApplied default: %s\n".printf (element, property, default), default);
    }

    public Error.unknown_attribute (string element, string property, string value) {
        this (ErrorKind.UNKNOWN_ATTRIBUTE, "%s.%s".printf (element, property), "This attribute is not supported by Froggum.\nElement: %s\nAttribute: %s\nValue: %s\n".printf (element, property, value), "");
    }

    public Error.invalid_property (string element, string property, string value, string default) {
        this (ErrorKind.INVALID_PROPERTY, "%s.%s".printf (element, property), "The given value for this attribute is not supported by Froggum\nElement: %s\nAttribute: %s\nValue: %s\nApplied default: %s\n".printf (element, property, value, default), default);
    }
}

public enum ErrorKind {
    CANT_READ,
    CANT_WRITE,
    INVALID_SVG,
    UNKNOWN_ELEMENT,
    UNKNOWN_ATTRIBUTE,
    INVALID_PROPERTY,
    MISSING_PROPERTY,
}

public enum Severity {
    WARNING,
    ERROR,
}

public Severity error_severity (ErrorKind kind) {
    switch (kind) {
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
    case UNKNOWN_ATTRIBUTE:
        return Severity.WARNING;
    default:
        return Severity.ERROR;
    }
}

