module common.allocators.BasicAllocator;

import common.all;
import common.allocators;

/**
 * Basic implementation of the Allocator interface.
 * 
 * Pros:
 *  - Relatively fast
 *  - Implements all Allocator interface methods
 *  - Allows freeing part of a previously allocated region
 *
 * Cons:
 *  - Will become fragmented over time if there are a lot of small allocations and frees
 *    * This will lead to slower allocations and small memory regions that cannot be allocated
 *  - Allocates from left to right. Can be slow if the regions are fragmented and/or the
 *    resource is nearly full
 *  - Not thread safe
 */
final class BasicAllocator : Allocator {
public:
    this(ulong sizeBytes) {
        this.sizeBytes = sizeBytes;
        reset();
    }

    override ulong numBytesFree() const { return freeBytes; }
    override ulong numBytesUsed() const { return sizeBytes-freeBytes; }
    override ulong size() const { return sizeBytes; }

    override long alloc(ulong size, uint alignment = 1) {
        _numAllocs++;
        /// Iterate through free regions from offset 0
        /// to find a region with enough space for _size_.
        foreach(i, ref b; array) {
            if(b.size==size) {
                // Free region is exactly the right size
                auto offset = b.offset;
                if(alignment>1 && (offset%alignment)!=0) continue;
                array.removeAt(i);
                freeBytes -= size;
                return offset;

            } else if(b.size > size) {
                // Free region is larger than requested size. Use part of this region
                ulong offset = b.offset;
                uint rem;
                if(alignment>1 && (rem=offset%alignment)!=0) {
                    // offset is not aligned correctly

                    int inc = alignment-rem;

                    if(b.size.as!long-inc < size.as!long) {
                        // region size is no longer big enough
                        continue;
                    } else if(b.size-inc==size) {
                        /// we can just reuse the free block as the inc block
                        /// |+++++++++++free++++++++++|   before
                        /// |++inc++| ----- used -----|   after
                        b.size = inc;
                    } else {
                        /// we need to create an extra small free block for inc
                        /// |++++++++++free+++++++++|    before
                        /// |+inc+|--used--|++free++|    after
                        b.offset  += (inc + size);
                        b.size    -= (inc + size);
                        array.insertAt(i, FreeRegion(offset,inc));
                    }
                    freeBytes -= size;
                    return offset + inc;
                }
                /// shrink this free block
                b.offset  += size;
                b.size    -= size;
                freeBytes -= size;
                return offset;
            }
        }
        return -1;
    }
    /// Free part of or all of an allocated region.
    /// Note that this is assumed to not overlap free regions.
    /// Freeing within an allocated region to create new free regions is ok.
    ///
    override void free(ulong offset, ulong size) {
        _numFrees++;
        ulong end = offset+size;

        int i = findFreeRegion(offset);
        //writefln("i=%s", i); 

        // Calculate prev and next region
        FreeRegion* b;
        FreeRegion* prev;
        FreeRegion* next;

        //if(i==array.length) i--;

        if(i!=-1) {
            b = &array[i];
            //writefln("b=%s", b.toString); 
        }

        if(!b) {

        } else if(b.offset<offset) {
            prev = b;
            next = i+1<array.length ? &array[i+1] : null;
        } else if(b.offset>offset) {
            if(i>0) {
                i--;
                prev = &array[i];
            }
            next = b;
        }
        //writefln("prev=%s", prev?prev.toString:null);
        //writefln("next=%s", next?next.toString:null);

        if(prev && next) {
            if(offset==prev.end && end==next.offset) {
                prev.size += size + next.size;
                array.removeAt(i+1);
            } else if(offset==prev.end) {
                prev.size += size;
            } else if(end==next.offset) {
                next.offset -= size;
                next.size   += size;
            } else {
                array.insertAt(i+1, FreeRegion(offset,size));
            }
        } else if(prev) {
            if(offset==prev.end) {
                prev.size += size;
            } else {
                array.insertAt(i+1, FreeRegion(offset,size));
            }
        } else if(next) {
            if(next.offset==end) {
                next.offset -= size;
                next.size   += size;
            } else {
                array.insertAt(i, FreeRegion(offset,size));
            }
        } else {
            array.insertAt(0, FreeRegion(offset,size));
        }
        freeBytes += size;
    }
    ///
    /// Free all allocations.
    ///
    override void reset() {
        freeBytes = sizeBytes;

        array.length = 0;
        array ~= FreeRegion(0,sizeBytes);
    }
    ///
    /// Set a new size. Setting a larger size always works. Setting a
    /// smaller size will only reduce down to the end of the last
    /// allocated region.
    ///
    override void resize(ulong newSize) {
        bool thereIsAnEmptyRegionAtEnd() {
            return array.length>0 && array.last().end==sizeBytes;
        }

        if(newSize > sizeBytes) {
            ulong difference = newSize-sizeBytes;

            if(thereIsAnEmptyRegionAtEnd()) {
                // expand end free region
                array.last().size += difference;
            } else {
                // create new free region at the end
                array ~= FreeRegion(sizeBytes,difference);
            }
            freeBytes += difference;
            sizeBytes += difference;
        } else {
            ulong difference = sizeBytes-newSize;

            if(thereIsAnEmptyRegionAtEnd()) {
                ulong regionSize = array.last.size;

                if(regionSize<=difference) {
                    // Delete the whole last free region
                    difference = regionSize;
                    array.removeAt(array.length-1);
                } else {
                    // shrink the last free region
                    array.last.size -= difference;
                }
                freeBytes -= difference;
                sizeBytes -= difference;
            } else {
                // Not possible to reduce
            }
        }
    }
    //──────────────────────────────────────────────────────────────────────────────────────────────────
    // Useful debugging functions not part of the Allocator interface.
    //──────────────────────────────────────────────────────────────────────────────────────────────────
    /**
     * 
     * Returns true if the index is within an allocated region.  
     */
    bool isAllocated(ulong index) {
        return -1 == findFreeRegionContainingOffset(index);
    }
    bool isEmpty() { return freeBytes==sizeBytes; }
    uint numAllocs() { return _numAllocs; }
    uint numFrees() { return _numFrees; }
    uint numFreeRegions() { return freeRegions().length.as!uint; }

    Tuple!(ulong,ulong)[] getFreeRegionsByOffset() {
        return freeRegions()
            .map!(it=>tuple(it[0], it[1]))
            .array;
    }
    Tuple!(ulong,ulong)[] getFreeRegionsBySize() {
        return freeRegions()
            .sort!((x,y) => x[1] < y[1])
            .map!(it=>tuple(it[0], it[1]))
            .array;
    }
    Tuple!(ulong,ulong)[] freeRegions() {
        Tuple!(ulong,ulong)[] buf;
        foreach(b; array) {
            buf ~= tuple(b.offset, b.size);
        }
        return buf;
    }
    override string toString() {
        string buf = "[BasicAllocator %s/%s bytes used (%s%%), %s free region%s] {\n".format(
            sizeBytes-freeBytes, sizeBytes,
            ((sizeBytes-freeBytes)*100.0) / sizeBytes,
            array.length,
            array.length==1 ? "" : "s");

        foreach(r; freeRegions()) {
            buf ~= "  %s - %s (%s bytes)\n".format(r[0], r[0]+r[1]-1, r[1]);
        }

        return buf ~ "}";
    }
private:
    ulong sizeBytes;
    ulong freeBytes;
    uint _numAllocs;
    uint _numFrees;
    FreeRegion[] array;

    static struct FreeRegion { 
        static assert(FreeRegion.sizeof==ulong.sizeof*2);

        ulong offset;
        ulong size;

        ulong end() const { return offset+size; }
        bool contains(ulong offset) { return this.offset <= offset && offset < end(); }

        string toString() { return "%s - %s".format(offset,end); }
    }
    /**
     * Use binary search to find the nearest free region.
     *
     * Returns -1 if there are no free regions.
     */
    int findFreeRegion(ulong offset) {
        if(array.length==0) return -1;
        if(array.length==1) return 0;

        // There are at least 2 free regions. Perform a binary search
        uint min = 0;
        uint max = array.length.as!uint;

        while(min<max) {
            auto mid = (min+max) >> 1;
            auto r   = array[mid];
            if(r.offset==offset) {
                // Exact match found
                return mid;
            } else if(r.offset > offset) {
                max = mid;
            } else {
                min = mid + 1;
            }
        }
        // Return FreeRegion index within array range
        return min == array.length ? min-1 : min;
    }
    /**
     * Use linear search to find the free region that contains the offset.
     *
     * Returns -1 if no free region contains the offset.
     */
    int findFreeRegionContainingOffset(ulong offset) {
        if(array.length==0) return -1;
        if(array.length==1) return array[0].contains(offset) ? 0 : -1;

        // There are at least 2 free regions. Perform a linear search
        uint min = 0;
        uint max = array.length.as!uint;

        while(min<max) {
            auto mid = (min+max) >> 1;
            auto r   = array[mid];
            if(r.contains(offset)) {
                // Match found
                return mid;
            } else if(r.offset > offset) {
                max = mid;
            } else {
                min = mid + 1;
            }
        }
        return -1;
    }
}
