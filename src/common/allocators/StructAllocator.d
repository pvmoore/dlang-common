module common.allocators.StructAllocator;

import common.all;
import common.allocators;

final class StructAllocator(T) if(is(T == struct)) : Allocator {
public:
    this(ulong maxStructs) {
        this.maxStructs = maxStructs;
    }
    void reset() {

    }

private:
    ulong maxStructs;
    
}
