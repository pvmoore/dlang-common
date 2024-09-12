module common.containers.async_queue;

import common.all;

enum ThreadingModel {
    SPSC,   // single producer single consumer
    MPSC,   // multiple producer single consumer
    SPMC,   // single producer multiple consumer
    MPMC    // multiple producer multiple consumer
}

//==========================================================

IQueue!T makeSPSCQueue(T)(uint cap) { return new Queue!(T,ThreadingModel.SPSC)(cap); }
IQueue!T makeMPSCQueue(T)(uint cap) { return new Queue!(T,ThreadingModel.MPSC)(cap); }
IQueue!T makeSPMCQueue(T)(uint cap) { return new Queue!(T,ThreadingModel.SPMC)(cap); }
IQueue!T makeMPMCQueue(T)(uint cap) { return new Queue!(T,ThreadingModel.MPMC)(cap); }


final class Queue(T,ThreadingModel TM) : IQueue!T {
private:
    const uint mask;
    T[] array;
    align(16) shared Positions pos;

    static struct Positions {
        int r;
        int w;
    }
    static assert(Positions.sizeof==8);

    enum IS_SINGLE_PRODUCER = TM==ThreadingModel.SPSC ||
                              TM==ThreadingModel.SPMC;

    enum IS_SINGLE_CONSUMER = TM==ThreadingModel.SPSC ||
                              TM==ThreadingModel.MPSC;

public:
    this(uint capacity) {
        throwIfNot(isPowerOf2(capacity), "Queue capacity must be a power of 2");
        this.array.length = capacity;
        this.mask         = capacity-1;
    }
    int length() {
        auto p = atomicLoad(pos);
        return p.w-p.r;
    }
    bool empty() { return length==0; }

    IQueue!T push(T value) {
        static if(IS_SINGLE_PRODUCER) {
            // cast away shared
            auto pptr = cast(Positions*)&pos;
            int p     = pptr.w;

            pptr.w = p+1;
            array[p&mask] = value;
        } else {
            int p = nextWritePos();
            array[p&mask] = value;
        }
        return this;
    }
    T pop() {
        Positions p;
        T value = T.init;

        do{
            p = atomicLoad(pos);
            if(p.r == p.w) break;

            value = array[p.r&mask];

        }while(!cas(&pos.r, p.r, p.r+1));

        // This might be faster but doesn't work on LDC in release mode:
        // (possibly due to undefined behaviour)
        
        // ulong p1;
        // ulong p2 = p1-1;

        // while(true) {
        //     auto old = cas64(cast(void*)&pos, p1, p2);
        //     if((old & 0xffffffff) == (old >>> 32)) break;
        //     if(old==p1) {
        //         value = array[p1&mask];
        //         break;
        //     }

        //     p1 = old;
        //     p2 = old;
        //     p2++;
        // }

        return value;
    }
    /**
     * Take 'here.length' items from the queue and put them in 'here'.
     * Returns the number taken.
     */
    uint drain(T[] here) {
        static if(IS_SINGLE_CONSUMER) {
            auto p = atomicLoad(pos);
            auto len = p.w-p.r;
            if(len==0) return 0;

            if(len>here.length) len = cast(int)here.length;

            uint start = p.r&mask;
            uint end   = (p.r+len)&mask;

            if(end>start) {
                here[0..len] = array[start..end];
            } else {
                auto n = array.length-start;
                here[0..n]     = array[start..array.length];
                here[n..n+end] = array[0..end];
            }

            auto pptr = cast(Positions*)&pos;
            pptr.r += len;
            return len;
        } else {
            Positions p2;
            int i;

            while(i<here.length) {
                auto p = atomicLoad(pos);
                if(p.r==p.w) break;

                p2.w = p.w;
                p2.r = p.r+1;

                if(cas(&pos, p, p2)) {
                    here[i++] = array[p.r&mask];
                }
            }
            return i;
        }
    }
    IQueue!T clear() {
        atomicSet64(cast(void*)&pos, 0L);
        //atomicStore(pos, Positions(0,0));
        return this;
    }
private:
    int nextReadPos() {
        int i;
        do{
            i = atomicLoad(pos.r);
        }while(!cas(&pos.r, i, i+1));
        return i;
    }
    int nextWritePos() {
        int i;
        do{
            i = atomicLoad(pos.w);
        }while(!cas(&pos.w, i, i+1));
        return i;
    }
}
