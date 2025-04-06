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

    // The 'size' parameter allows for partial freeing which may not be supported by the implementation.
    void free(ulong index, ulong size);
    
    void reset();
    ulong size();
    void resize(ulong newSize);
    ulong numBytesFree();
    ulong numBytesUsed();
}

import common.allocators.ArenaAllocator;
import common.allocators.BasicAllocator;
import common.allocators.FreeList;
import common.allocators.HeapStorage;
import common.allocators.SparseArrayIndexes;
import common.allocators.StaticFreeList;
import common.allocators.StructStorage;
