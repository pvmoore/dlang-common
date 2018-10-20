module common.allocator;

import common.all;
import std.traits : isUnsigned, Signed;

alias Allocator = Allocator_t!ulong;
///
/// TODO - Create another class that defragments the memory.
///        This defrag needs to have the ability to move memory
///        around in the client.
///        Call it _AllocatorDefrag_ or similar.
///
final class Allocator_t(T) {
    static assert(isUnsigned!T);
private:
    T sizeBytes;
    T freeBytes;
    uint _numAllocs;
    uint _numFrees;
    Array!FreeRegion array;

    static final struct FreeRegion {
        T offset;
        T size;

        pragma(inline,true)
        T end() const { return offset+size; }
        string toString() { return "%s - %s".format(offset,end); }
    }
    static assert(FreeRegion.sizeof==T.sizeof*2);
public:
    T numBytesFree() const { return freeBytes; }
    T numBytesUsed() const { return sizeBytes-freeBytes; }
    T length() const { return sizeBytes; }
    bool empty() const { return freeBytes==sizeBytes; }
    uint numAllocs() const { return _numAllocs; }
    uint numFrees() const { return _numFrees; }
    uint numFreeRegions() {
        return cast(uint)freeRegions().length;
    }
    Tuple!(T,T)[] getFreeRegionsByOffset() {
        return freeRegions()
            .map!(it=>tuple(it[0], it[1]))
            .array;
    }
    Tuple!(T,T)[] getFreeRegionsBySize() {
        return freeRegions()
            .sort!((x,y) => x[1] < y[1])
            .map!(it=>tuple(it[0], it[1]))
            .array;
    }
    Tuple!(T,T)[] freeRegions() {
        auto buf = appender!(Tuple!(T,T)[]);
        foreach(ref b; array) {
            buf ~= tuple(b.offset, b.size);
        }
        return buf.data;
    }
    /// Returns 0 if there are no allocations
    T offsetOfLastAllocatedByte() {
        if(empty()) return 0;
        if(array.empty) return sizeBytes-1;

        auto lastFreeRegion = array.last();
        if(lastFreeRegion.end()==sizeBytes) return lastFreeRegion.offset-1;
        return sizeBytes-1;
    }

    this(T sizeBytes) {
        this.sizeBytes = sizeBytes;
        this.array     = new Array!FreeRegion;
        freeAll();
    }
    Signed!T alloc(T size, uint alignment=1) {
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
                T offset = b.offset;
                T rem;
                if(alignment>1 && (rem=offset%alignment)!=0) {
                    T inc = alignment-rem;
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
    void free(T offset, T size) {
        _numFrees++;
        T end = offset+size;

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
    void freeAll() {
        array.clear();
        freeBytes = sizeBytes;

        array.add(FreeRegion(0,sizeBytes));
    }
    ///
    /// Set a new size. Setting a larger size always works. Setting a
    /// smaller size will only reduce down to the end of the last
    /// allocated region.
    ///
    void resize(T newSize) {
        bool thereIsAnEmptyRegionAtEnd() {
            return array.length>0 && array.last.end==sizeBytes;
        }

        if(newSize > sizeBytes) {
            T difference = newSize-sizeBytes;

            if(thereIsAnEmptyRegionAtEnd()) {
                // expand end free region
                array.last.size += difference;
            } else {
                // create new free region at the end
                array.add(FreeRegion(sizeBytes,difference));
            }
            freeBytes += difference;
            sizeBytes += difference;
        } else {
            T difference = sizeBytes-newSize;

            if(thereIsAnEmptyRegionAtEnd()) {
                T regionSize = array.last.size;

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
    int findRegion(T offset) {
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
