module common.allocators.StructStorage;

import common.all;
import common.allocators;

final class StructStorage(T) if(is(T == struct)) {
public:
    uint numUsed() { return freeList.numUsed(); }
    uint numFree() { return freeList.numFree(); }

    this(uint maxStructs) {
        this.structs.length = maxStructs;
        this.freeList = new FreeList(maxStructs);
    }
    void reset() {
        this.freeList.reset();
    }
    T* alloc() {
        throwIf(freeList.numFree() == 0, "Struct storage is full");

        uint index = freeList.acquire();
        return &structs[index];
    }
    void free(T* ptr) {
        assert(ptr >= structs.ptr && ptr < structs.ptr + structs.length);
        uint index = ((ptr - structs.ptr) / T.sizeof).as!uint;
        freeList.release(index);

        // reset the struct in the storage
        structs[index] = T.init;
    }

private:
    T[] structs;
    FreeList freeList;
}
