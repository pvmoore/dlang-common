module common.containers.Set;
/**
 *  An unordered collection of unique items.
 *
 */
final class Set(T) {
private:
    bool[T] map;
    bool isFrozen;
public:
    int length() const { return cast(int)map.length; }
    bool empty() const { return length==0; }
    T[] values() { return map.keys; }

    auto add(T value) {
        if(isFrozen) throw new Exception("Attempingt to modify an unmodifiable Set");
        map[value] = true;
        return this;
    }
    auto add(T[] values) {
        foreach(v; values) add(v);
        return this;
    }
    auto add(Set!T other) {
        foreach(v; other.map.keys()) add(v);
        return this;
    }
    bool remove(T value) {
        if(isFrozen) throw new Exception("Attempingt to modify an unmodifiable Set");
        bool* ptr = value in map;
        if(ptr) map.remove(value);
        return ptr !is null;
    }
    bool contains(T value) const {
        return (value in map) !is null;
    }
    /**
     * Set this Set instance as unmodifiable
     */
    auto freeze() {
        this.isFrozen = true;
        return this;
    }
    auto clear() {
        if(isFrozen) throw new Exception("Attempingt to modify an unmodifiable Set");
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
}