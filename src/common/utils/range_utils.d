module common.utils.range_utils;

import common.utils.utilities : throwIf;
import std.range;

/**
 * auto value = [1,2,3].filter!(it=>it>2).frontOrElse(0);
 */
T frontOrElse(T,Range)(Range r, T defaultValue) {
    return cast(T)(r.empty ? defaultValue : r.front);
}
