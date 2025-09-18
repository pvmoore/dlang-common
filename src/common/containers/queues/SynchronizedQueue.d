module common.containers.queues.SynchronizedQueue;

import common.all;

final class SynchronizedQueue(T) : IQueue!T {
    T[] array;
    int head, tail;
    uint mask;
    int len;

    this(uint length) {
        assert(isPowerOf2(length));

        this.mask = length-1;
        this.array.length = length;
    }

    override bool empty() { synchronized(this) return len == 0; }
    override int length() { synchronized(this) return len; }

    override IQueue!T push(T value) {
        synchronized(this) {
            len++;
            array[head] = value;
            head = (head+1) & mask;
            return this;
        }
    }
    override T pop() {
        synchronized(this) {
            if(empty()) return T.init;
            auto value = array[tail];
            tail = (tail+1) & mask;
            len--;
            return value;
        }
    }
    override uint drain(T[] here) {
        synchronized(this) {
            int i = 0;
            for(; len>0 && i<here.length; i++) {   
                here[i] = array[tail];
                tail = (tail+1) & mask;
                len--;
            }
            return i;
        }
    }
    override IQueue!T clear() {
        synchronized(this) {
            len = 0;
            head = tail = 0;
            return this;
        }
    }
}
