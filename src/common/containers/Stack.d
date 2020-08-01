module common.containers.Stack;

import common.all;

final class Stack(T) {
private:
    T[] array;
    int pos;
public:
    override string toString() {
        return "%s".format(array[0..pos]);
    }
    this(uint startLength = 8) {
        array.length = startLength;
    }
    uint length() const { return pos; }
    bool empty() const { return pos==0; }

    bool opEquals(T[] other) const {
        return pos==other.length && array[0..pos] == other;
    }
    bool opEquals(Stack!T other) const {
        return opEquals(other.array[0..other.pos]);
    }
    T[] opSlice() {
        return array[0..pos];
    }

    auto push(T v) {
        expand();
        array[pos++] = v;
        return this;
    }
    T pop() {
        if(pos==0) return T.init;
        return array[--pos];
    }
    T peek(int offset = 0) {
        int i = pos-(offset+1);
        if(i < 0 || i >= array.length) return T.init;
        return array[i];
    }
    auto clear() {
        pos = 0;
        return this;
    }
    auto pack() {
        array.length = pos;
        return this;
    }
    bool contains(T value) const {
        for(auto i=0; i<pos; i++) {
            if(array[i]==value) return true;
        }
        return false;
    }
private:
    pragma(inline,true)
    void expand() {
        if(pos==array.length) {
            array.length = (array.length+1)*2;
        }
    }
}

