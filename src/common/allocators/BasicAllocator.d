module common.allocators.BasicAllocator;

import common.all;
import common.allocators;

final class BasicAllocator : Allocator {
private:
    ulong sizeBytes;
    ulong freeBytes;
    uint _numAllocs;
    uint _numFrees;
    FreeRegion[] array;

    static struct FreeRegion {
        ulong offset;
        ulong size;

        pragma(inline,true)
        ulong end() const { return offset+size; }
        string toString() { return "%s - %s".format(offset,end); }
    }
    static assert(FreeRegion.sizeof==ulong.sizeof*2);
public:
    override ulong numBytesFree() const { return freeBytes; }
    override ulong numBytesUsed() const { return sizeBytes-freeBytes; }
    override ulong size() const { return sizeBytes; }

    bool isEmpty() const { return freeBytes==sizeBytes; }

    uint numAllocs() const { return _numAllocs; }
    uint numFrees() const { return _numFrees; }
    uint numFreeRegions() {
        return cast(uint)freeRegions().length;
    }
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
        auto buf = appender!(Tuple!(ulong,ulong)[]);
        foreach(ref b; array) {
            buf ~= tuple(b.offset, b.size);
        }
        return buf.data;
    }
    /// Returns 0 if there are no allocations
    ulong offsetOfLastAllocatedByte() {
        if(isEmpty()) return 0;
        if(array.isEmpty()) return sizeBytes-1;

        auto lastFreeRegion = array.last();
        if(lastFreeRegion.end()==sizeBytes) return lastFreeRegion.offset-1;
        return sizeBytes-1;
    }

    this(ulong sizeBytes) {
        this.sizeBytes = sizeBytes;
        reset();
    }
    override long alloc(ulong size, uint alignment=1) {
        _numAllocs++;
        /// Iterate through free regions from offset 0
        /// to find a region with enough space for _size_.
        foreach(i, ref b; array) {
            if(b.size==size) {
                auto offset = b.offset;
                if(alignment>1 && (offset%alignment)!=0) continue;
                array.removeAt(i);
                freeBytes -= size;
                return offset;
            } else if(b.size > size) {
                ulong offset = b.offset;
                ulong rem;
                if(alignment>1 && (rem=offset%alignment)!=0) {
                    ulong inc = alignment-rem;
                    if(b.size-inc==size) {
                        /// we can just reuse the free block as the inc block
                        /// |+++++++++++free++++++++++|   before
                        /// |++inc++| ----- used -----|   after
                        b.size = inc;
                    } else if(b.size-inc<size) {
                        continue;
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

        int i = findRegion(offset);
        //writefln("i=%s", i); flushStdErrOut();

        FreeRegion* b;
        FreeRegion* prev;
        FreeRegion* next;

        if(i==array.length) i--;

        if(i!=-1) {
            b = &array[i];
            //writefln("b=%s", b.toString); flushStdErrOut();
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
        array.length = 0;
        freeBytes = sizeBytes;

        array ~= FreeRegion(0,sizeBytes);
    }
    ///
    /// Set a new size. Setting a larger size always works. Setting a
    /// smaller size will only reduce down to the end of the last
    /// allocated region.
    ///
    void resize(ulong newSize) {
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
    string getStats() {
        return "[allocs=%s, frees=%s]".format(_numAllocs, _numFrees);
    }
    override string toString() {
        auto buf = appender!(string[]);
        buf ~= "--------------";
        buf ~= "[Allocator %s/%s (%s%%) bytes used (%s free regions)] {".
            format(sizeBytes-freeBytes, sizeBytes,
           ((sizeBytes-freeBytes)*100.0) / sizeBytes,
           array.length);

        foreach(r; freeRegions()) {
            buf ~= "  %s - %s (%s bytes)".format(r[0],r[0]+r[1]-1, r[1]);
        }

        buf ~= "}";
        return buf.data.join("\n");
    }
private:
    int findRegion(ulong offset) {
        if(array.length==0) return -1;
        if(array.length==1) return 0;

        uint min = 0;
        uint max = cast(uint)array.length;
        while(min<max) {
            auto mid = (min+max)>>1;
            auto r   = array[mid];
            if(r.offset==offset) {
                return mid;
            } else if(r.offset > offset) {
                max = mid;
            } else {
                min = mid+1;
            }
        }
        return min;
    }
}
