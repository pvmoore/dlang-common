module common.allocators;

public:

/**
 * Allocator interface.
 *
 * Keeps track of memory allocations within a contiguous resource (memory, file, etc). 
 * Does not actually store anything.
 */
interface Allocator {
    long alloc(ulong size, uint alignment = 1);

    // The 'size' parameter allows for partial freeing but we may not want to allow this
    void free(ulong index, ulong size);
    
    void reset();
    ulong size();
    void resize(ulong newSize);
    ulong numBytesFree();
    ulong numBytesUsed();
}

import common.allocators.BasicAllocator;
import common.allocators.HeapStorage;
