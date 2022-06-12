module common.utils.regex_utils;

import std.regex : Regex, regex, matchFirst;

bool matches(string str, Regex!char r) {
    return !matchFirst(str, r).empty;
}
bool matches(Regex!char r, string str) {
    return !matchFirst(str, r).empty;
}

bool matchesAny(string str, Regex!(char)[] regexes...) {
    foreach(r; regexes) {
        if(!matchFirst(str,r).empty) return true;
    }
    return false;
}