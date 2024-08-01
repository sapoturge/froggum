public enum ErrorKind {
    NO_ERROR,
    CANT_READ,
    CANT_WRITE,
    INVALID_SVG,
    UNKNOWN_ELEMENT,
    UNKNOWN_ATTRIBUTE,
}

public enum Severity {
    WARNING,
    ERROR,
    NO_ERROR,
}

public Severity error_severity (ErrorKind kind) {
    switch (kind) {
    case NO_ERROR:
        return Severity.NO_ERROR;
    case CANT_READ:
        return Severity.ERROR;
    case CANT_WRITE:
        return Severity.ERROR;
    case INVALID_SVG:
        return Severity.ERROR;
    case UNKNOWN_ELEMENT:
        return Severity.WARNING;
    case UNKNOWN_ATTRIBUTE:
        return Severity.WARNING;
    default:
        return Severity.ERROR;
    }
}

