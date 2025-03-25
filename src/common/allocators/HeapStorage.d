module common.allocators.HeapStorage;

import common.all;
import common.allocators;

/**
 * Simple RAM heap storage 
 *
 *
 */
class HeapStorage {
public:
    ulong size() { return _size; }
    
    this(ulong size, Allocator allocator) {
        this.allocator = allocator;
        this._size = size;
        this.heap = new ubyte[size];
    }
    void reset() {
        allocator.reset();
    }
    void* allocate(ulong size, uint alignment = 1) {
        long pos = allocator.alloc(size, alignment);
        return null;
    }
    void free(void* ptr) {
        //allocator.free(ptr);
    }
private:
    Allocator allocator;
    ulong _size;
    ubyte[] heap;
}
