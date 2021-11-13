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

// bool equals(T)(T[] array, T value) {
//     for(auto i=0; i<array.length; i++) {
//         if(array[i] != value) return false;
//     }
//     return true;
// }
bool equals(T)(T[] array, T[] values) {
    if(array.length != values.length) return false;
    for(auto i=0; i<array.length; i++) {
        if(array[i] != values[i]) return false;
    }
    return true;
}

int indexOf(T)(T[] array, T value) if(!isSomeChar!T) {
    foreach(i, v; array) if(v==value) return cast(int)i;
    return -1;
}

void insertAt(T)(ref T[] array, long atPos, T extra) {
	assert(atPos<=array.length);
	array.insertInPlace(atPos, extra);
}
void insertAt(T)(ref T[] array, long atPos, T[] extra) {
	assert(atPos<=array.length);
	array.insertInPlace(atPos, extra);
}
/// returns true if the entire array only contains values
bool onlyContains(T)(T[] array, T value) nothrow {
	foreach(v; array) {
        if(v!=value) return false;
    }
	return true;
}
void push(T)(ref T[] array, T value) {
	array ~= value;
}
T pop(T)(ref T[] array) {
	if(array.length==0) return T.init;
	T value = array[$-1];
	array.length = array.length - 1;
	return value;
}
T remove(T)(ref T[] array, T value) {
	foreach(i, v; array) {
        if(v is value) {
            return array.removeAt(i);
        }
    }
    return T.init;
}
/** array.removeAt(i) */
T removeAt(T)(ref T[] array, long index) {
	assert(index<array.length);
	T element = array[index];
	foreach(ref v; array[index+1..$]) {
		array[index++] = v;
	}
	array.length = array.length - 1;
	return element;
}
/** array.removeRange(start,end) inclusive */
void removeRange(T)(ref T[] array, long start, long end) {
	assert(start <= end);
	long span = (end-start)+1;
	foreach(v; array[end+1..$]) {
		array[start++] = v;
	}
	array.length = array.length - span;
}

/**
 * Append a U[] to a T[]
 */
T[] add(T,U)(return ref T[] dest, U[] array) {
	dest ~= cast(T[])array;
	return dest;
}