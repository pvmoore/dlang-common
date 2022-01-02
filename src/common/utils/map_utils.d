module common.utils.map_utils;

import std.traits 				: isAssociativeArray;
import std.typecons 			: Tuple, tuple;


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

/**
 * uint[ulong] theMap;
 * Tuple!(ulong,uint)[] e = theMap.entries();
 */
Tuple!(K,V)[] entries(K,V)(V[K] theMap) {
	import std.range : array;
	import std.algorithm.iteration : map;

	return theMap.byKeyValue().map!(it=>tuple(it.key, it.value)).array;
}
/**
 * uint[ulong] theMap;
 * Tuple!(ulong,uint)[] e = theMap.sortedEntries((a,b)=>a[0] > b[0]);
 */
Tuple!(K,V)[] sortedEntries(K,V)(V[K] theMap, bool function(Tuple!(K,V) a, Tuple!(K,V) b) comp) {
	import std.range : array;
	import std : map, sort;

	auto arr = theMap.byKeyValue().map!(it=>tuple(it.key, it.value)).array;

	sort!(comp)(arr);

	return arr;
}
Tuple!(K,V)[] sortedEntriesByKey(K,V)(V[K] theMap, bool ascending = true) {
	return ascending ? theMap.sortedEntries!(K,V)((a,b)=>a[0] < b[0])
					 : theMap.sortedEntries!(K,V)((a,b)=>a[0] > b[0]);
}
Tuple!(K,V)[] sortedEntriesByValue(K,V)(V[K] theMap, bool ascending = true) {
	return ascending ? theMap.sortedEntries!(K,V)((a,b)=>a[1] < b[1])
					 : theMap.sortedEntries!(K,V)((a,b)=>a[1] > b[1]);
}