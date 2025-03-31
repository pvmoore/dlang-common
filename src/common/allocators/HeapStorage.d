module common.allocators.HeapStorage;

import common.all;
import common.allocators;

/**
 * Simple RAM heap storage 
 *
 * There is no resize function since that is likely to reallocate memory and invalidate
 * the client pointers.
 */
class HeapStorage {
public:
    ulong size() { return heap.length; }
    ulong numBytesUsed() { return allocator.numBytesUsed(); }
    ulong numBytesFree() { return allocator.numBytesFree(); }
    
    this(Allocator allocator) {
        this.allocator = allocator;
        this.heap = new ubyte[allocator.size()];
    }
    void reset() {
        allocator.reset();
        allocations.clear();
        heap[] = 0;
    }
    void* alloc(ulong size, uint alignment = 1) {
        long offset = allocator.alloc(size, alignment);
        if(offset == -1) return null;

        allocations[offset] = size;
        return &heap[offset];
    }
    void free(void* ptr) {
        assert(ptr);
        assert(ptr >= heap.ptr && ptr < heap.ptr + heap.length);

        ulong offset = (heap.ptr - ptr.as!(ubyte*)).as!ulong; 
        ulong size = allocations.get(offset, -1);
        throwIf(size == -1, "Freeing ptr that was not allocated: 0xX", ptr);

        allocator.free(offset, size);
        allocations.remove(offset);

        // zero the freed memory
        heap[offset .. offset + size] = 0;
    }
private:
    Allocator allocator;
    ubyte[] heap;
    ulong[ulong] allocations;
}
