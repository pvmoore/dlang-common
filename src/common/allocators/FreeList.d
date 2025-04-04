module common.allocators.FreeList;

import common.all;

/**
 * Keep track of slot index usage. Acquire and release as necessary.
 * Allows for fast reuse of slots.
 *
 * The list is stored in heap allocated memory.
 */
final class FreeList {
public:
    uint numUsed() { return _numUsed; }
    uint numFree() { return list.length.as!uint - _numUsed; }
    uint size()    { return list.length.as!uint; }

    this(uint length) {
        list.length = length;
        reset();
    }
    void reset() {
        foreach(i; 0..list.length) {
            list[i] = i.as!uint+1;
        }
        next = 0;
        _numUsed = 0;
    }
    uint acquire() {
        throwIf(_numUsed==list.length, "FreeList is full");
        auto index = next;
        next = list[next];
        _numUsed++;
        return index;
    }
    void release(uint index) {
        list[index] = next;
        next = index;
        _numUsed--;
    }
private:
    uint[] list;
    uint next;
    uint _numUsed;    
}
