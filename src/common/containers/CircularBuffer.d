module common.containers.CircularBuffer;

import common.all;

interface ICircularBuffer(T) {
    bool isEmpty();
    uint size();
    ICircularBuffer add(T value);
    T take();
}

final class CircularBuffer(T) : ICircularBuffer!T {
private:
    const uint MASK;

    uint start;
    uint end;
    T[] buffer;
    uint _size;
public:
    this(uint size) {
        throwIf(!isPowerOf2(size), "The buffer length must be a power of 2");

        this.buffer.length = size;
        this.MASK = size-1;
        this.start = 0;
        this.end = 0;
    }

    override uint size() { return _size; }
    override bool isEmpty() { return size()==0; }

    override ICircularBuffer!T add(T value) {
        throwIf(_size==buffer.length);

        buffer[end] = value;
        end = (end+1) & MASK;
        _size++;
        return this;
    }
    override T take() {
        throwIf(_size==0);

        T value = buffer[start];
        start = (start+1) & MASK;
        _size--;
        return value;
    }
}

/**
 * A CircularBuffer which always has a contiguous buffer of at least _size_
 * that can be accessed.
 *
 */
final class ContiguousCircularBuffer(T) : ICircularBuffer!T {
private:
    const uint MASK;
    const uint MAX_SIZE;

    uint start1, start2;
    uint end1, end2;
    T[] buffer1;
    T[] buffer2;
    uint _size;
public:
    this(uint size) {
        throwIf(!isPowerOf2(size), "The buffer length must be a power of 2");

        this.MAX_SIZE = size;
        this.MASK = size*2-1;
        this.buffer1.length = size*2;
        this.buffer2.length = size*2;
        this.start1 = 0;
        this.start2 = size;
        this.end1 = 0;
        this.end2 = size;
    }

    /** A contiguous view of the buffer contents */
    T[] slice() { return start1 < start2 ? buffer1[start1..start1+_size]
                                         : buffer2[start2..start2+_size];
    }
    override uint size() { return _size; }
    override bool isEmpty() { return size()==0; }

    override ICircularBuffer!T add(T value) {
        throwIf(_size==MAX_SIZE);

        buffer1[end1] = value;
        buffer2[end2] = value;
        end1 = (end1+1) & MASK;
        end2 = (end2+1) & MASK;
        _size++;
        return this;
    }
    override T take() {
        throwIf(_size==0);
        T value = buffer1[start1];
        start1 = (start1+1) & MASK;
        start2 = (start2+1) & MASK;
        _size--;
        return value;
    }
}