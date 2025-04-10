module common.containers.UniqueList;

import common.containers;
import utils = common.utils;
import std.stdio;
import std.format : format;

final class UniqueList(T) {
private:
    T[] list;
    Set!T set;
public:
    this() {
        this.set = new Set!T();
    }

    T[] values() { return list; }
    ulong length() { return list.length; }
    bool isEmpty() { return list.length == 0; }

    auto add(T value) {
        auto beforeSize = set.size();
        set.add(value);
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
    bool remove(T value) {
        if(set.remove(value)) {
            utils.remove(list, value);
            return true;
        }
        return false;
    }
    bool contains(T value) {
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
