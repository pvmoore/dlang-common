module common.utils.map_utils;

import std.traits : isAssociativeArray;

/// mymap.contains(myvalue)
bool containsKey(M,V)(M map, V value) if(isAssociativeArray!M) {
	return (value in map) !is null;
}
/**
 * Add or replace values in map with values in other.
 *  map1.add(map2);
 */
void add(M)(ref M map, M other) if(isAssociativeArray!M) {
    foreach(k, v; other) {
        map[k] = v;
    }
}
void putIfAbsent(K,V)(ref V[K] map, K key, V value) {
	auto p = key in map;
	if(!p) {
		map[key] = value;
	}
}
/**
 * auto p = map.getOrAdd("default");
 */
V* getOrAdd(K,V)(ref V[K] map, K key, V addMe) {
	auto p = key in map;
	if(p) return p;

	map[key] = addMe;
	return key in map;
}