module common.containers.Stack;

import std.format : format;

final class Stack(T, U = uint) {
public:
    U length() const { return pos; }
    bool isEmpty() const { return pos==0; }

    this(uint reserveCapacity = 0) {
        if(reserveCapacity > 0) {
            array.reserve(reserveCapacity);
        }
    }
    void push(T value) {
        expand();
        array[pos++] = value;
    }
    T pop() {
        if(pos==0) return T.init;
        T value = array[--pos];
        return value;
    }
    T peek(U offset = 0) {
        if(offset >= pos) return T.init;
        return array[pos-offset-1];
    }
    void clear(bool release = false) {
        pos = 0;
        if(release) array = null;
    }
    bool contains(T value) const {
        foreach(i; 0..pos) {
            if(array[i]==value) return true;
        }
        return false;
    }
    T[] opSlice() {
        return array[0..pos];
    }
    override string toString() {
        return "%s".format(array[0..pos]);
    }
private:
    T[] array;
    U pos;

    void expand() {
        if(pos==array.length) {
            if(array.length == 0) {
                array.length = 8;
            } else {
                array.length = array.length*2;
            }
        }
    }
}

