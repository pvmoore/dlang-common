module common.containers.UniqueList;

import common.containers;
import utils = common.utils;
import std.stdio;
import std.format : format;

/**
 * Ordered list of unique items. Uses Set internally to ensure uniqueness.
 */
final class UniqueList(T) {
private:
    T[] list;
    Set!T set;
public:
    this() {
        this.set = new Set!T();
    }

    /** Returns the underlying array */
    T[] values()   { return list; }
    ulong length() const { return list.length; }
    bool isEmpty() const { return list.length == 0; }

    auto add(T value) {
        auto beforeSize = set.size();
        set.add(value);
        // Only add to the list if we don't already have it
        if(set.size() > beforeSize) {
            list ~= value;
        }
        return this;
    }
    auto add(T[] values) {
        foreach(v; values) {
            add(v);
        }
        return this;
    }
    /** Remove value from the list and return true if it was removed otherwise false if it wasn't in the list */
    bool remove(T value) {
        if(set.remove(value)) {
            utils.remove(list, value);
            return true;
        }
        return false;
    }
    bool contains(T value) const {
        return set.contains(value);
    }
    auto clear() {
        list.length = 0;
        set.clear();
        return this;
    }
    override string toString() const {
        return "%s".format(list);
    }
}
