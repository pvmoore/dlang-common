module common.containers.Map;

import common.all;

/**
 *  class Wrapper for the in-built associative array.
 */
class Map(K,V) {
protected:
    alias This = Map!(K,V);
    V[K] map;
public:
final:
    int length() { return cast(int)map.length; }
    bool isEmpty() { return length==0; }
    K[] keys() { return map.keys(); }
    V[] values() { return map.values(); }
    auto byKey() { return map.byKey(); }
    auto byValue() { return map.byValue(); }
    auto byKeyValue() { return map.byKeyValue(); }

    This add(K key, V value) {
        map[key] = value;
        return this;
    }
    This add(V[K] otherMap) {
        foreach(e; otherMap.byKeyValue()) {
            map[e.key] = e.value;
        }
        return this;
    }
    This add(This otherMap) {
        add(otherMap.map);
        return this;
    }
    This update(K key, V delegate() createFunc, V delegate(V) updateFunc) {
        map.update(key, createFunc, updateFunc);
        return this;
    }
    V* opIndex(K key) {
        return key in map;
    }
    void opIndexAssign(V value, K key) {
        map[key] = value;
    }
    V* get(K key) {
        return key in map;
    }
    bool remove(K key) {
        return map.remove(key);
    }
    bool containsKey(K key) {
        return (key in map) !is null;
    }
    bool containsAllKeys(K[] keys...) {
        foreach(k; keys) {
            if((k in map) is null) return false;
        }
        return true;
    }
    bool containsAnyKeys(K[] keys...) {
        foreach(k; keys) {
            if((k in map) !is null) return true;
        }
        return false;
    }
    bool containsValue(V value) {
        foreach(v; values()) {
            if(v==value) return true;
        }
        return false;
    }
    This clear() {
        map.clear();
        return this;
    }
    This rehash() {
        map.rehash();
        return this;
    }
    override string toString() {
        string s = "[";
        foreach(e; map.byKeyValue()) {
            if(s.length>1) s ~= ", ";
            s ~= "%s:%s".format(e.key, e.value);
        }
        return s ~ "]";
    }
}