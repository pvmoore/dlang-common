module common.utils.range_utils;

import common.utils.utilities : throwIf;
import std.range;

/** 
 * InputRange:
 *      T front();          // return the first element
 *      void popFront();    // remove the first element
 *      bool empty();       // return true if the range is empty
 * 
 * ForwardRange:  
 *      T front();          // return the first element
 *      void popFront();    // remove the first element
 *      bool empty();       // return true if the range is empty
 *      auto save();        // save the state of the range
 *
 * BidirectionalRange:
 *      T front();
 *      T back();
 *      void popFront();
 *      void popBack();
 *      bool empty();
 *      bool save();
 *
 * RandomAccessRange:
 *      T front();
 *      T back();
 *      void popFront();
 *      void popBack();
 *      bool empty();
 *      bool save();
 *      T opIndex(size_t);
 *      size_t length();
 */

/**
 * Return the front of the range or the default value if the range is empty.
 * 
 * auto value = [1,2,3].filter!(it=>it>2).frontOrElse(0);
 */
T frontOrElse(T,Range)(Range r, T defaultValue) {
    return cast(T)(r.empty ? defaultValue : r.front);
}
