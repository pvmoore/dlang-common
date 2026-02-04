module common.utils.array_utils;

import std.array  : insertInPlace;
import std.traits : isSomeString, isSomeChar;

/** 
 * Return the first element of the array. Assumes the array is not empty
 */
ref T first(T)(T[] array) {
	assert(array.length > 0);
	return array[0];
}

/** 
 * Return the last element of the array. Assumes the array is not empty
 */
ref T last(T)(T[] array) {
	assert(array.length > 0);
	return array[$-1];
}

/** 
 * Return true if the array length == 0
 */
bool isEmpty(T)(T[] array) {
	return array.length == 0;
}

/**
 *  eg.
 *  int[] intArray;
 *  intArray.contains(2)
 */
bool contains(T)(T[] values, T value) if(!isSomeChar!T) {
    foreach(v; values) if(v==value) return true;
	return false;
}

/// returns true if the entire array only contains 'value'
bool onlyContains(T)(T[] array, T value) nothrow {
	foreach(v; array) {
        if(v!=value) return false;
    }
	return true;
}

int indexOf(T)(T[] array, T value) if(!isSomeChar!T) {
    foreach(i, v; array) if(v==value) return cast(int)i;
    return -1;
}

/** 
 * array.insertAt(1, 50)
 *      .insertAt(3, 30);
 */
ref T[] insertAt(T)(return ref T[] array, ulong atPos, T extra) {
	assert(atPos <= array.length);
	array.insertInPlace(atPos, extra);
	return array;
}
ref T[] insertAt(T)(return ref T[] array, ulong atPos, T[] extra) {
	assert(atPos <= array.length);
	array.insertInPlace(atPos, extra);
	return array;
}

/** 
 * array.replaceAt(1, [50, 60])
 *      .replaceAt(6, [30, 40]);
 */
ref T[] replaceAt(T)(return ref T[] array, ulong atPos, T[] values) {
	assert(atPos < array.length);
	assert(atPos+values.length <= array.length);
	array[atPos..atPos+values.length] = values;
	return array;
}

/** 
 * Add a value to the end of the array.
 * eg.
 * array.push(1).push(2).push(3);
 */
ref T[] push(T)(return ref T[] array, T value) {
	array ~= value;
	return array;
}

/** 
 * Remove and return the last element of the array.
 * eg.
 * T p = array.pop();
 */
T pop(T)(ref T[] array) {
	if(array.length==0) return T.init;
	T value = array[$-1];
	array.length = array.length - 1;
	return value;
}

/** 
 * Remove and return the first instance of 'value' in the array. 'defaultValue' is returned if 'value' is not found.
 */
T remove(T)(ref T[] array, T value, T defaultValue = T.init) {
	foreach(i, v; array) {
        if(v == value) {
            return array.removeAt(i);
        }
    }
    return defaultValue;
}

/** 
 * Remove and return the element at 'index' in the array.
 *
 * auto v = array.removeAt(i) 
 */
T removeAt(T)(ref T[] array, ulong index) {
	assert(index < array.length);

	T element = array[index];

	import core.stdc.string : memmove;

	T* dest    = array.ptr + index;
	T* src     = array.ptr + index + 1;
	ulong size = (array.length - index) - 1;

	memmove(dest, src, size * T.sizeof);

	array.length = array.length - 1;
	return element;
}
/** 
 * Remove and return the element at 'index' in the array. The last element is moved to the vacated slot.
 * This is faster than removeAt() but changes the order of the array.
 */
T unorderedRemoveAt(T)(ref T[] array, ulong index) {
	assert(index < array.length);

	T element = array[index];
	array[index] = array[$-1];
	array.length--;
	return element;
} 

T removeFirstMatch(T)(ref T[] array, bool delegate(T value) pred, T defaultValue = T.init) {
	foreach(i, v; array) {
		if(pred(v)) {
			return array.removeAt!T(i);
		}
	}
	return defaultValue;
}

/** array.removeRange(start,end) inclusive */
void removeRange(T)(ref T[] array, ulong start, ulong end) {
	assert(start <= end);
	assert(end < array.length);

	// todo - use memmove here instead. would be much faster
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

/** 
 * Append a value to array T[] and return a pointer to the value
 */
T* appendAndReturnPtr(T)(ref T[] dest, T value) {
	dest ~= value;
	return &dest[$-1];
}
