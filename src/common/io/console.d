module common.io.console;

import common.io;

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
    version(assert) {
        writefln("%s", i);
        flushConsole();
    }
}
void dbg(A...)(string fmt, A args) {
    version(assert) {
        writefln(fmt, args);
        flushConsole();
    }
}
void dbg(string s) {
    version(assert) {
        writeln(s);
        flushConsole();
    }
}

version(Win64) {
import core.sys.windows.windows;

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
} // Win64