module common.utils.array_utils;

import std.array	: insertInPlace;
import std.traits   : isSomeString, isSomeChar;
/**
 *  eg.
 *  int[] intArray;
 *  intArray.contains(2)
 */
bool contains(T)(T[] values, T value) if(!isSomeChar!T) {
    foreach(v; values) if(v==value) return true;
	return false;
}

int indexOf(T)(T[] array, T value) if(!isSomeChar!T) {
    foreach(i, v; array) if(v==value) return cast(int)i;
    return -1;
}

bool equals(T)(T[] array, T value) {
    for(auto i=0; i<array.length; i++) {
        if(array[i] != value) return false;
    }
    return true;
}
bool equals(T)(T[] array, T[] values) {
    if(array.length != values.length) return false;
    for(auto i=0; i<array.length; i++) {
        if(array[i] != values[i]) return false;
    }
    return true;
}

void insert(T)(ref T[] array, long atPos, T extra) {
	array.insertInPlace(atPos, extra);
}
void insert(T)(ref T[] array, long atPos, T[] extra) {
	array.insertInPlace(atPos, extra);
}
T remove(T)(ref T[] array, T value) {
	foreach(i, v; array) {
        if(v is value) {
            return array.removeAt(i);
        }
    }
    return T.init;
}
/// array.removeAt(i)
T removeAt(T)(ref T[] array, long index) {
	T element = array[index];
	foreach(v; array[index+1..$]) {
		array[index++] = v;
	}
	array.length = array.length - 1;
	return element;
}
/// array.removeAt(start,end) inclusive
void removeAt(T)(ref T[] array, long start, long end) {
	long span = (end-start)+1;
	foreach(v; array[end+1..$]) {
		array[start++] = v;
	}
	array.length = array.length - span;
}

void push(T)(ref T[] array, T value) {
	array ~= value;
}
T pop(T)(ref T[] array) {
	T value = array[$-1];
	array.length = array.length - 1;
	return value;
}