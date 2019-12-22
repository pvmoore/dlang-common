module common.async.async_queue;

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
    T[] array;
    shared Positions pos;
    uint mask;
    static struct Positions {
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
        auto p = atomicLoad(pos);
        return p.w-p.r;
    }
    bool empty() { return length==0; }

    IQueue!T push(T value) {
        static if(isSP) {
            // cast away shared
            auto pptr = cast(Positions*)&pos;
            int p     = pptr.w;

            pptr.w = p+1;
            array[p&mask] = value;
        } else {
            int pos = nextWritePos();
            array[pos&mask] = value;
        }
        return this;
    }
    T pop() {
        static if(isSC) {
            // cast away shared
            auto pptr = cast(Positions*)&pos;
            int p = pptr.r;
            pptr.r = p+1;
            return array[p&mask];
        } else {
            int pos = nextReadPos();
            return array[pos&mask];
        }
    }
    /**
     * Take 'here.length' items from the queue and put them
     * in 'here'.
     * Returns the number taken.
     */
    uint drain(T[] here) {
        static if(isSC) {
            auto p = atomicLoad(pos);
            auto len = p.w-p.r;
            if(len==0) return 0;
            if(len>here.length) len = cast(int)here.length;

            here[0..len] = array[pos.r .. pos.r+len];
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
    static bool isSP() pure {
        return TM==ThreadingModel.SPSC ||
               TM==ThreadingModel.SPMC;
    }
    static bool isSC() pure {
        return TM==ThreadingModel.SPSC ||
               TM==ThreadingModel.MPSC;
    }
}
