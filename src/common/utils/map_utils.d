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
void add(M)(M map, M other) if(isAssociativeArray!M) {
    foreach(k, v; other) {
        map[k] = v;
    }
}
