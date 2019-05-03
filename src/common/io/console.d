module common.io.console;

private import core.sys.windows.windows;
private import std.stdio;
private import std.format : format;
private import std.utf    : toUTF16;

void flushConsole() {
    import core.stdc.stdio : fflush, stderr, stdout;
    fflush(stderr);
    fflush(stdout);
}
/**
 *  Debug console logging. Always flushes console after writing.
 */
void dbg(int i) {
    writefln("%s", i);
    flushConsole();
}
void dbg(A...)(string fmt, A args) {
    writefln(fmt, args);
    flushConsole();
}

final class Console {
public:
    enum Attrib : ushort {
        NORMAL	  = WHITE,
        BLACK     = 0,
        RED       = FOREGROUND_RED,
        GREEN     = FOREGROUND_GREEN,
        BLUE      = FOREGROUND_BLUE,
        YELLOW    = RED   | GREEN,
        MAGENTA   = RED   | BLUE,
        CYAN      = GREEN | BLUE,
        WHITE     = RED	  | GREEN | BLUE,

        UNDERSCORE = COMMON_LVB_UNDERSCORE,
        INVERSE    = COMMON_LVB_REVERSE_VIDEO,
        INTENSE    = FOREGROUND_INTENSITY,

        BG_RED     = BACKGROUND_RED,
        BG_GREEN   = BACKGROUND_GREEN,
        BG_BLUE    = BACKGROUND_BLUE,
        BG_YELLOW  = BG_RED | BG_GREEN,
        BG_MAGENTA = BG_RED | BG_BLUE,
        BG_CYAN    = BG_GREEN | BG_BLUE,
        BG_INTENSE = BACKGROUND_INTENSITY,
    }
    static void set(uint attr) {
        auto handle = GetStdHandle(STD_OUTPUT_HANDLE);
        SetConsoleTextAttribute(handle, cast(ushort)attr);
    }
    static void reset() {
        set(Attrib.NORMAL);
    }
}
