module common.set;
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
}