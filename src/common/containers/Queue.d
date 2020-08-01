module common.containers.Queue;

import common.all;

interface IQueue(T) {
    bool empty();
    int length();
    IQueue!T push(T value);
    T pop();
    uint drain(T[] array);
    IQueue!T clear();
}

/**
 *  Single threaded queue.
 */
final class Queue(T) : IQueue!T {
private:
    T[] array;
    Positions pos;
    uint mask;
    static final struct Positions {
        int r;
        int w;
    }
    static assert(Positions.sizeof==8);
public:
    this(uint capacity) {
        if(!isPowerOf2(capacity)) throw new Error("Queue capacity must be a power of 2");
        this.array.length = capacity;
        this.mask         = capacity-1;
    }
    int length() {
        return pos.w-pos.r;
    }
    bool empty() { return length==0; }

    IQueue!T push(T value) {
        int p = pos.w++;
        array[p&mask] = value;
        return this;
    }
    IQueue!T pushToFront(T value) {
        int p = --pos.r;
        array[p&mask] = value;
        return this;
    }
    T pop() {
        int p = pos.r++;
        return array[p&mask];
    }
    ///
    /// Return a copy of values.
    ///
    T[] valuesDup() {
        auto buf = appender!(T[]);
        for(int i = pos.r; i<pos.w; i++) {
            buf ~= array[i&mask];
        }
        return buf.data;
    }
    /**
     * Take 'here.length' items from the queue and put them
     * in 'here'.
     * Returns the number taken.
     */
    uint drain(T[] here) {
        auto i = cast(int)here.length;
        if(i>length) i = length;
        here[0..i] = array[pos.r .. pos.r+i];
        pos.r += i;
        return i;
    }
    IQueue!T clear() {
        pos = Positions(0,0);
        return this;
    }
}
