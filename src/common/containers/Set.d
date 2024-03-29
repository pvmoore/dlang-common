module common.containers.Set;

import std.format : format;

/**
 *  An unordered collection of unique items.
 *
 */
class Set(T) {
protected:
    bool[T] map;
public:
    int length() const { return cast(int)map.length; }
    bool empty() const { return length==0; }
    T[] values() { return map.keys; }

    Set!T add(T value) {
        map[value] = true;
        return this;
    }
    Set!T add(T[] values) {
        foreach(v; values) add(v);
        return this;
    }
    auto add(Set!T other) {
        foreach(v; other.map.keys()) add(v);
        return this;
    }
    bool remove(T value) {
        bool* ptr = value in map;
        if(ptr) map.remove(value);
        return ptr !is null;
    }
    bool contains(T value) const {
        return (value in map) !is null;
    }
    Set!T clear() {
        map.clear();
        return this;
    }
    override size_t toHash() const @safe pure nothrow {
        throw new Error("Doesn't make sense to use this as a key");
    }
    /// This is a semi-expensive process
    override bool opEquals(Object o) const {
        Set other = cast(Set!T)o;
        if(other is null) return false;

        if(length!=other.length) return false;

        foreach(k; other.map.keys) {
            if(!(k in map)) return false;
        }
        return true;
    }
    override string toString() {
        string s = "[";
        foreach(i, ref T k; values()) {
            if(i>0) s ~= ", ";
            s ~= "%s".format(k);
        }
        return s ~ "]";
    }
}