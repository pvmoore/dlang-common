module common.allocators.StaticFreeList;

import common.all;
import std.range : iota, staticArray;

/**
 * Keep track of slot index usage. Acquire and release as necessary.
 * Allows for fast reuse of slots.
 *
 * The list is created as a static array as part of the StaticFreeList struct.
 */
struct StaticFreeList(uint LENGTH) {
public:
    uint numUsed() { return _numUsed; }
    uint numFree() { return LENGTH - _numUsed; }
    uint size()    { return LENGTH; }

    // Disable copy constructor
    @disable this(ref StaticFreeList!LENGTH);

    void reset() {
        foreach(i; 0..LENGTH) {
            list[i] = i.as!uint+1;
        }
        next = 0;
        _numUsed = 0;
    }
    uint acquire() {
        throwIf(_numUsed==LENGTH, "StaticFreeList is full");
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
    uint[LENGTH] list = iota(0, LENGTH).map!((uint i) => i+1).staticArray!(uint[LENGTH]);
    uint next;
    uint _numUsed;    
}
