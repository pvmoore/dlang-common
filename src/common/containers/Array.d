module common.containers.Array;

import common.all;

final class Array(T) {
private:
	T[] array;
	ulong len;
public:
    T* ptr() { return array.ptr; }
    bool empty() const { return len==0; }
    ulong length() const { return len; }
    ulong reservedLength() const { return array.length; }

    override string toString() const {
        return "%s".format(array[0..len]);
    }
	this(int reserve=8) {
        array.length = reserve;
	}
    auto clone() {
        import std.traits : hasElaborateCopyConstructor;

        auto temp = new Array!T(length().as!uint);

        static if(hasElaborateCopyConstructor!T) {
            foreach(i; 0..length()) {
                temp.add(array[i]);
            }
        } else {
            // Blit everything across
            temp.array.length = length();
            temp.len = length();
            temp.array[0..length()] = array[0..length()];
        }
        return temp;
    }

	/// Getters and setters. All assume you have checked the length
    ref T front() {
        return array[0];
    }
    T front() const {
        return cast(T)array[0];
    }
	ref T first() {
        return array[0];
	}
    T first() const {
        return cast(T)array[0];
    }

	ref T last() {
	    return array[len-1];
	}
    T last() const {
        return cast(T)array[len-1];
    }

	ref T opIndex(ulong i) {
		return array[i];
	}
    T opIndex(ulong i) const {
        return cast(T)array[i];
    }

	//T[] opIndex() {
	//    return array[0..len];
	//}

    T[] values() {
        return array[0..len];
    }
	T[] opSlice() {
	    return values();
	}
    immutable(T)[] opSlice() const {
        return cast(immutable(T)[])array[0..len];
    }
	T[] opSlice(ulong from, ulong to) {
        return array[from..to];
    }
    immutable(T)[] opSlice(ulong from, ulong to) const {
        return cast(immutable(T)[])array[from..to];
    }

    long opDollar() const {
        return len;
    }
	void opIndexAssign(T val, ulong i) {
		array[i] = val;
	}
    override size_t toHash() nothrow {
        if(len==0) return 0;
        ulong a = 5381;
        for(auto i=0; i<len; i+=4) {
            a  = (a << 7)  + hashOf!T(array[i]);
            a ^= (a << 13) + hashOf!T(array[i+1]);
            a  = (a << 19) + hashOf!T(array[i+2]);
            a ^= (a << 23) + hashOf!T(array[i+3]);
        }
        foreach(i; len%3..len) {
            a  = (a << 7) + hashOf(array[i]);
        }
        return a;
    }
	bool opEquals(inout(T)[] o) const {
        return array[0..len] == o;
	}
	bool opEquals(Array!T o) const {
	    return opEquals(o.array[0..o.length]);
	}
    // foreach(a; array)
	int opApply(scope int delegate(ref T) dg) {
        int result = 0;

        for(int i = 0; i < len; i++) {
            result = dg(array[i]);
            if(result) break;
        }
        return result;
	}
    // foreach(i, a; array)
    int opApply(scope int delegate(ulong n, ref T) dg) {
        int result = 0;

        for(ulong i = 0; i < len; i++) {
            result = dg(i, array[i]);
            if(result) break;
        }
        return result;
    }
    auto opOpAssign(string op)(T val) {
        static if(op=="~") {
            return add(val);
        } else static assert(false, "Array!%s %s= %s is not implemented".format(T.stringof, op, T.stringof));
    }
    auto opOpAssign(string op)(T[] vals) {
        static if(op=="~") {
            return add(vals);
        } else static assert(false, "Array!%s %s= %s[] is not implemented".format(T.stringof, op, T.stringof));
    }

	auto add(T val) {
	    expand(1);
		array[len++] = val;
		return this;
	}
	auto add(T[] values) {
        expand(values.length);
        array[len..len+values.length] = values[];
        len+=values.length;
        return this;
	}
    T remove(T value) {
        for(int i=0; i<len; i++) {
            if(array[i]==value) {
                return removeAt(i);
            }
        }
        return T.init;
    }
	T removeAt(ulong index) {
	    T val = array[index];
	    len--;

        static if(__traits(isPOD,T)) {
            memmove(
                array.ptr+index,        // dest
                array.ptr+index+1,      // src
                (len-index)*T.sizeof);  // num bytes
        } else {
            for(auto j = index; j<len; j++) {
                array[j] = array[j+1];
            }
        }
	    return val;
	}
	auto removeAt(ulong index, ulong count) {
	    if(count==0) return this;
	    if(index+count>len) count = len-index;

        static if(__traits(isPOD,T)) {
            if(index+count<len) {
                memmove(
                    array.ptr+index,                // dest
                    array.ptr+index+count,          // src
                    (len-(index+count))*T.sizeof);  // num bytes
            }
        } else {
            for(auto j = index; j<len-count; j++) {
                array[j] = array[j+count];
            }
        }
        len -= count;
	    return this;
	}
	auto insertAt(ulong index, T value) {
	    expand(1);

        static if(__traits(isPOD,T)) {
            memmove(
                array.ptr+index+1,          // dest
                array.ptr+index,            // src
                (len-index)*T.sizeof);      // num bytes
        } else {
            for(auto i = len-1; i>=index; i--) {
                array[i+1] = array[i];
            }
        }
	    array[index] = value;
        len++;
	    return this;
	}
	auto insertAt(ulong index, T[] values) {
	    auto count = values.length;
	    if(count==0) return this;
        expand(count);

        static if(__traits(isPOD,T)) {
            memmove(
                array.ptr+index+count,      // dest
                array.ptr+index,            // src
                (len-index)*T.sizeof);      // num bytes
        } else {
            for(auto dest = len+(count-1); dest>=index+count; dest--) {
                array[dest] = array[dest-count];
            }
        }
        array[index..index+count] = values;
        len += count;
	    return this;
	}
	auto move(ulong from, ulong to) {
        if(from==to) return this;
        if(from>=len || to>=len) {
            throw new Error("Array: Range error (len=%s from=%s to=%s)".format(
                len, from, to
            ));
        }
        T value = array[from];

        static if(__traits(isPOD,T)) {
            if(to<from) {
                // backwards
                memmove(
                    array.ptr+to+1,           // dest
                    array.ptr+to,           // src
                    (from-to)*T.sizeof);    // num bytes
            } else {
                // forwards
                memmove(
                    array.ptr+from,          // dest
                    array.ptr+from+1,        // src
                    (to-from)*T.sizeof);      // num bytes
            }
        } else {
            if(to<from) {
                // backwards
                for(auto i = from; i>to; i--) {
                    array[i] = array[i-1];
                }
            } else {
                // forwards
                for(auto i = from; i<to; i++) {
                    array[i] = array[i+1];
                }
            }
        }
        array[to] = value;
	    return this;
	}
	auto clear() {
		len = 0;
		return this;
	}
    auto pack() {
        array.length = len;
        return this;
    }
    int indexOf(T val) const {
        for(int i=0; i<len; i++)
            if(array[i]==val) return i;
        return -1;
    }
    bool contains(T val) const {
        return indexOf(val)!=-1;
    }
private:
    pragma(inline,true)
    void expand(long count) {
        if(len+count >= array.length) {
            auto newLength = (len+count+1)*2;
            array.length = newLength;
            //writefln("length=%s", array.length);
        }
    }
}
