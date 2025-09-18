module common.containers.queues.MutexQueue;

import common.all;

final class MutexQueue(T) : IQueue!T {
    T[] array;
    Mutex lock;
    int head, tail;
    uint mask;
    int len;

    this(uint length) {
        assert(isPowerOf2(length));

        this.mask = length-1;
        this.array.length = length;
        this.lock = new Mutex;
    }

    override bool empty() { 
        lock.lock();
        scope(exit) lock.unlock();

        return len == 0; 
    }
    override int length() { 
        lock.lock();
        scope(exit) lock.unlock();

        return len; 
    }
    override IQueue!T push(T value) {
        lock.lock();
        scope(exit) lock.unlock();

        len++;
        array[head] = value;
        head = (head+1) & mask;
        return this;
    }
    override T pop() {
        lock.lock();
        scope(exit) lock.unlock();

        if(empty()) return T.init;
        auto value = array[tail];
        tail = (tail+1) & mask;
        len--;
        return value;
    }
    override uint drain(T[] here) {
        lock.lock();
        scope(exit) lock.unlock();

        int i = 0;
        for(; len>0 && i<here.length; i++) {   
            here[i] = array[tail];
            tail = (tail+1) & mask;
            len--;
        }
        return i;
    }
    override IQueue!T clear() {
        lock.lock();
        scope(exit) lock.unlock();

        len = 0;
        head = tail = 0;
        return this;
    }
}
