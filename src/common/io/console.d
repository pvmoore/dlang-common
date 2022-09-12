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

/**
 * writefln("%sHello%s", Ansi.RED, Ansi.RESET);
 */
enum Ansi : string {
    BLACK           = "\u001b[30m",
    RED             = "\u001b[31m",
    GREEN           = "\u001b[32m",
    YELLOW          = "\u001b[33m",
    BLUE            = "\u001b[34m",
    MAGENTA         = "\u001b[35m",
    CYAN            = "\u001b[36m",
    WHITE           = "\u001b[37m",

    BLACK_BOLD      = "\u001b[30;1m",
    RED_BOLD        = "\u001b[31;1m",
    GREEN_BOLD      = "\u001b[32;1m",
    YELLOW_BOLD     = "\u001b[33;1m",
    BLUE_BOLD       = "\u001b[34;1m",
    MAGENTA_BOLD    = "\u001b[35;1m",
    CYAN_BOLD       = "\u001b[36;1m",
    WHITE_BOLD      = "\u001b[37;1m",

    BLACK_BG        = "\u001b[40m",
    RED_BG          = "\u001b[41m",
    GREEN_BG        = "\u001b[42m",
    YELLOW_BG       = "\u001b[43m",
    BLUE_BG         = "\u001b[44m",
    MAGENTA_BG      = "\u001b[45m",
    CYAN_BG         = "\u001b[46m",
    WHITE_BG        = "\u001b[47m",

    BLACK_BOLD_BG   = "\u001b[40;1m",
    RED_BOLD_BG     = "\u001b[41;1m",
    GREEN_BOLD_BG   = "\u001b[42;1m",
    YELLOW_BOLD_BG  = "\u001b[43;1m",
    BLUE_BOLD_BG    = "\u001b[44;1m",
    MAGENTA_BOLD_BG = "\u001b[45;1m",
    CYAN_BOLD_BG    = "\u001b[46;1m",
    WHITE_BOLD_BG   = "\u001b[47;1m",

    BOLD            = "\u001b[1m",
    UNDERLINE       = "\u001b[4m",
    INVERSE         = "\u001b[7m",

    RESET           = "\u001b[0m",
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