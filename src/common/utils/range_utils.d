module common.utils.range_utils;

import common.utils.utilities : throwIf;
import std.range;

/**
 * auto value = [1,2,3].filter!(it=>it>2).frontOrDefault(0);
 */
T frontOrDefault(T,Range)(Range r, T defaultValue) {
    return cast(T)(r.empty ? defaultValue : r.front);
}
