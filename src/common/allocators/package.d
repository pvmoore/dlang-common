module common.allocators;

///
/// TODO - Create another class that defragments the memory.
///        This defrag needs to have the ability to move memory
///        around in the client.
///        Call it _AllocatorDefrag_ or similar.
///

public:

interface Allocator {
    long alloc(ulong size, uint alignment = 1);
    void free(ulong index, ulong size);
    void reset();

    ulong size();
    ulong numBytesFree();
    ulong numBytesUsed();
}

import common.allocators.BasicAllocator;
