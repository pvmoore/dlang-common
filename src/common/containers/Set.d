module common.containers.Set;
/**
 *  An unordered collection of unique items.
 *
 */
final class Set(T) {
private:
    bool[T] map;
public:
    int length() const { return cast(int)map.length; }
    bool empty() const { return length==0; }
    T[] values() { return map.keys; }

    auto add(T value) {
        map[value] = true;
        return this;
    }
    auto add(T[] values) {
        foreach(v; values) add(v);
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
    auto clear() {
        map.clear();
        return this;
    }
    override size_t toHash() const @safe pure nothrow {
        // Doesn't make sense to use this as a key
        assert(false);
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
}