module common.allocators.ArenaAllocator;

import common.all;
import common.allocators;

/**
 * Simple fast allocator that allocates from a fixed size buffer. 
 * Freeing is not implemented. The client is expected to reset or create a new Arena
 * when capacity is reached. 
 */
final class ArenaAllocator : Allocator {
public:
    this(ulong size) {
        this.numBytes = size;
    }

    override ulong numBytesFree() { 
        return numBytes - ptr; 
    }
    override ulong numBytesUsed() { 
        return ptr; 
    }
    override void reset() {
        this.ptr = 0;
    }
    override long alloc(ulong size, uint alignment = 1) {

        ulong offset = getAlignedValue(ptr, alignment);

        // Not enough space
        if(offset + size > numBytes) {
            return -1;
        }
        this.ptr = offset + size;
        return offset;
    }
    override void free(ulong index, ulong size) {
        // Not implemented
    }
    override ulong size() {
        return numBytes;
    }
    override void resize(ulong newSize) {
        this.numBytes = newSize;
        if(this.ptr > newSize) {
            this.ptr = newSize;
        }
    }    
private:
    ulong numBytes;
    ulong ptr;
}
