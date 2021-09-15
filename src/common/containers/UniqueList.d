module common.containers.UniqueList;

import common.containers;
import utils = common.utils;
import std.stdio;

final class UniqueList(T) : Set!T {
private:
    T[] list;
public:
    override T[] values() { return list; }

    override UniqueList!T add(T value) {
        auto len = length();
        super.add(value);
        if(len<length) {
            list ~= value;
        }
        return this;
    }
    override UniqueList!T add(T[] values) {
        super.add(values);
        return this;
    }
    override bool remove(T value) {
        utils.remove(list, value);
        return super.remove(value);
    }
    override UniqueList!T clear() {
        list.length = 0;
        super.clear();
        return this;
    }
    override size_t toHash() const @safe pure nothrow {
        return list.hashOf();
    }
    override bool opEquals(Object o) const {
        UniqueList!T other = cast(UniqueList!T)o;
        if(o is this) return true;
        return o !is null && list == other.list;
    }
    bool opEquals(T[] array) {
        return list.length == array.length && list == array;
    }
}