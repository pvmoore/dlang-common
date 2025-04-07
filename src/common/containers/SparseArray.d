module common.containers.SparseArray;

import common.all;
import core.bitop : bsf, bsr, popcnt;

/**
 * ** What is SparseArray? **
 * SparseArray is a dynamic array that is optimised for a sparsely populated data set. It can be used 
 * in a similar way to a flat array but if the number of items is small the memory usage is less than
 * a flat array. Access is slower than a flat array but should still be reasonable.
 *
 * Values are not appended but can be set at any index even outside the capacity which will grow as required.
 * The length() of the array is the number of items stored. Capacity() grows in increments of 64.
 * eg. 
 *   sparseArray[100] = 5;
 *   This array is now length() == 1 and capacity() == 128
 *   sparseArray.values() == [5]
 *
 *   sparseArray[1000] = 99;
 *   This array is now length() == 2 and capacity() == 1024
 *   sparseArray.values() == [5, 99]
 *
 * ** How it works **
 * SparseArray keeps a record of positions of items in a sparsely populated array in a way that
 * uses less memory than a simple flat array.
 * 
 * It does this by using a smaller array of bit flags to mark the positions of items. This bit array
 * is itself not fully created unless required (WIP). 
 *
 * When calling sparseIndexOf() the bit array is used to find the index of the item in the flat array.
 * Another structure is used to keep a running count of the number of items in the sparse array in order
 * to make lookup more efficient. 
 *
 * Example:
 *
 * A SparseArray of capacity 1024 can hold up to 1024 item indexes. It is optimised to hold only a few
 * items so filling it up too much would be less efficient than just using a flat array. 
 * The indexes are used to lookup the actual item in a separate flat array which can be 
 * much smaller.
 *
 * ulong index = SparseArray.sparseIndexOf(1000);
 * auto item = items[index];
 *
 * ** Counts Tree **
 *
 * The counts are stored in an implied tree structure.
 *
 * 16 counts example:
 *
 *               pivot=8
 * ┌───────────────┬───────────────┐               
 * |       2       |       3       | 
 * ├───────┬───────┼───────┬───────┤  pivots at 4 and 12             
 * |   0   |   2   |   2   |   1   |
 * ├───┬───┼───┬───┼───┬───┼───┬───┤  pivots at 2,6,10 and 14             
 * | 0 | 0 | 0 | 2 | 1 | 1 | 0 | 1 |
 * ├─┬─┼─┬─┼─┬─┼─┬─┼─┬─┼─┬─┼─┬─┼─┬─┤  pivots at 1,3,5,7,9,11,13 and 15              
 * |0|0|0|0|0|0|1|1|1|0|0|1|0|0|0|1|
 * └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘  
 *  0 1 2 3 4 5 6 7 8 9 1 1 1 1 1 1
 *                      0 1 2 3 4 5   
 *
 * Tree representation in memory:
 *
 * tree = [00                // row 0
 *         0000              // row 1
 *         00000000          // row 2
 *         0000000000000000] // row 3 (length = capacity/64)
 *
 * Capacity   | Num bytes used | Using L0 ubytes | Using L1..8 ushorts | Using L9..24 uints
 * -----------|----------------|-----------------|---------------------|-------------------
 * 1,024      | 368            | 256             | 172                 | 172
 * 2,048      | 752            | 528             | 348                 | 348
 * 4,096      | 1,520          | 1,072           | 700                 | 700    
 * 8,192      | 3,056          | 2,160           | 1,404               | 1,404
 * 16,384     | 6,128          | 4,336           | 2,812               | 2,812
 * 65,536     | 24,560         | 17,392          | 11,272              | 11,264
 * 2,097,152  | 786,416        | 557,040         | 361,200             | 360,696
 * 4,194,304  | 1,572,848      | 1,114,096       | 722,416             | 721,400
 * 8,388,608  | 3,145,712      | 2,228,208       | 1,444,848           | 1,442,808
 * 16,777,216 | 6,291,440      | 4,456,432       | 2,889,712           | 2,885,624
 */
final class SparseArray(T) {
public:
    bool isEmpty() {
        return data.length == 0;
    }
    ulong length() {
        return data.length; 
    }
    ulong capacity() {
        return bits.length * 64;
    }
    ulong numBytesUsed() {
        return bits.length*8 +  
               L0Counts.length*1 + 
               L1To8Counts.length*2 + 
               L9To24Counts.length*4 +
               L25AndAboveCounts.length*8;
    }

    this() {
        this.initialCapacity = 0;
    }
    this(ulong capacity) {
        assert(popcnt(capacity) == 1);
        this.initialCapacity = capacity-1;
        clear();
    }
    /** auto v = array[index]; */
    T opIndex(ulong index) {
        return getItem(index);
    }
    /** v[index] = 3; */
    void opIndexAssign(T value, ulong index) {
        if(index >= capacity()) expand(index);
        
        if(isBitSet(index)) {
            replaceItem(index, value);
        } else {
            addItem(index, value);
        }
    }
    /**
     * Removes a value from the array.
     * Returns true if the value was removed or false if it was not found.
     */
    bool remove(ulong index) {
        if(index >= capacity()) return false;
        if(!isBitSet(index)) return false;

        removeItem(index);
        return true;
    }
    /** Resets the array to empty */
    void clear() {
        layers = 0;
        L0Counts = null;
        L1To8Counts = null;
        L9To24Counts = null;
        L25AndAboveCounts = null;
        bits = null;
        data = null;

        if(initialCapacity != 0) {
            expand(initialCapacity);
        }
    }
    /** Return a new array containing the values in the sparse array */
    T[] values() {
        return data.dup;
    }
    /** Return a RandomAccessRange of a snapshot of the values in the sparse array */
    auto range() {
        static struct SparseArrayRange {
            T[] values;
            ulong f, b;
            bool empty() { return f+b >= values.length; }
            T front() { return values[f]; }
            T back() { return values[($-1)-b]; }
            void popFront() { f++; }
            void popBack() { b++; }
            auto save() { return this; }
            T opIndex(size_t i) { return values[i]; }
            ulong length() { return values.length; }
        }
        return SparseArrayRange(values());
    }
    /** foreach(T value; array) {} */
    int opApply(int delegate(ref T value) dg) {
        int result = 0;
        foreach(i; 0..data.length) {
            T value = data[i];
            result = dg(value);
            if(result) break;
        }
        return result;
    }
    /** foreach(ulong index, T value; array) {} */
    int opApply(int delegate(ref ulong index, ref T value) dg) {
        int result = 0;
        foreach(i; 0..data.length) {
            ulong index = i;
            T value = data[i];
            result = dg(index, value);
            if(result) break;
        }
        return result;
    }
    // For debugging
    void dump() {
        writefln("┌───────────────────────────────────────────────────────────────────────────");
        writefln("│ numItems = %s, capacity = %s, (%s bytes used)", data.length, bits.length*64, numBytesUsed());
        
        uint size = 2;
        ulong offset = 0;

        writefln("│ L9..n  (%s):", L25AndAboveCounts.length);
        if(L25AndAboveCounts.length > 0) {
            while(offset < L25AndAboveCounts.length) {
                writef("│ [%2s] ", offset);
                foreach(i; offset..offset+size) {
                    writef(" %s", L25AndAboveCounts[i]);
                }
                writefln("");
                offset += size;
                size <<= 1;
            }
        }

        writefln("│ L9..24 (%s):", L9To24Counts.length);
        offset = 0;
        if(L9To24Counts.length > 0) {
            while(offset < L9To24Counts.length) {
                writef("│ [%2s] ", offset);
                foreach(i; offset..offset+size) {
                    writef(" %s", L9To24Counts[i]);
                }
                writefln("");
                offset += size;
                size <<= 1;
            }
        }

        writefln("│ L1..8  (%s):", L1To8Counts.length);
        offset = 0;
        if(L1To8Counts.length > 0) {
            while(offset < L1To8Counts.length) {
                writef("│ [%2s] ", offset);
                foreach(i; offset..offset+size) {
                    writef(" %s", L1To8Counts[i]);
                }
                writefln("");
                offset += size;
                size <<= 1;
            }
        }

        writefln("│ L0     (%s):", L0Counts.length);
        if(L0Counts.length > 0) {
            writef("│ ");
            foreach(i; 0..L0Counts.length) {
                writef(" %s", L0Counts[i]);
            }
        writefln("");
        }

        writefln("│ BITS (%s*ulong = %s bits):", bits.length, bits.length*64);
        foreach(j; 0..bits.length) {
            if(bits[j] != 0) {
                writef("│  [%2s] ", j);
                foreach(i; 0..64) {
                    writef("%s", isBitSet(j*64+i) ? 1 : 0);
                }
                writefln("");
            } 
        }

        writefln("│ DATA   (%s):", data.length);
        if(data.length > 0) {
            writef("│ ");
            foreach(i; 0..data.length) {
                writef(" %s", data[i]);
            }
            writefln("");
        }
        writefln("└───────────────────────────────────────────────────────────────────────────");
    }
private:
    const ulong initialCapacity;  // the capacity specified during creation
    uint capacityDiv;             // bsf(capacity) - 1
    uint layers;                  // Number of layers in the counts tree

    // Layer counts:
    // 
    // These are split into four separate arrays to reduce memory usage since we can take advantage
    // of the knowledge of the maximum possible count at each layer.
    // 
    // Layer [25] = 4294967296 ulong 
    ulong[] L25AndAboveCounts;

    // Layer [24] = 2147483648 uint 
    // Layer [23] = 1073741824 uint 
    // Layer [22] = 536870912 uint
    // Layer [21] = 268435456 uint 
    // Layer [20] = 134217728 uint 
    // Layer [19] = 67108864 uint
    // Layer [18] = 33554432 uint  
    // Layer [17] = 16777216 uint 
    // Layer [16] = 8388608 uint 
    // Layer [15] = 4194304 uint 
    // Layer [14] = 2097152 uint 
    // Layer [13] = 1048576 uint 
    // Layer [12] = 524288 uint 
    // Layer [11] = 262144 uint  
    // Layer [10] = 131072 uint  
    // Layer [9]  = 65536 uint   
    uint[] L9To24Counts;

    // Layer [8] = max 32768 
    // Layer [7] = max 16384 
    // Layer [6] = max 8192      
    // Layer [5] = max 4096  
    // Layer [4] = max 2048  
    // Layer [3] = max 1024  
    // Layer [2] = max 512   
    // Layer [1] = max 256  
    ushort[] L1To8Counts;

    // Layer [0] = max 128 (64*2)
    ubyte[] L0Counts;

    // todo- We can turn this into a sparse array using the bottom row of the counts tree
    //       to indicate whether a bits block is used or not
    ulong[] bits;

    // This is the real array of items
    T[] data;

    bool isBitSet(ulong index) {
        return (bits[index >>> 6] & (1UL << (index & 63))) != 0;
    }
    void setBit(ulong index) {
        bits[index >>> 6] |= 1UL << (index & 63);
    }
    void clearBit(ulong index) {
        bits[index >>> 6] &= ~(1UL << (index & 63));
    }

    /** Expand tree to hold the given index+1. Minimum capacity is 64 */
    void expand(ulong requiredIndex) {
        // Capacity needs to be >= required index + 1
        // eg. index = 0 requires capacity of at least 1 item
        requiredIndex++;

        enum MIN_CAPACITY = 64;
        uint pc = popcnt(requiredIndex);
        ulong newCapacity = pc == 0 ? MIN_CAPACITY : 1 << (bsr(requiredIndex) + (pc == 1 ? 0 : 1));
        newCapacity = newCapacity < MIN_CAPACITY ? MIN_CAPACITY : newCapacity;
        recreateTree(newCapacity);
    }
    void recreateTree(ulong newCapacity) {
        assert(popcnt(newCapacity) == 1);
        assert((newCapacity & 63) == 0);

        bool propagateRequired = bits.length > 0;

        // This will reallocate the array if necessary
        bits.length = newCapacity/64;

        this.capacityDiv = bsf(bits.length) - 1; 

        // Create the bottom layer of counts (which may be length 0)
        ulong L0CountsLength = bits.length & ~1UL;
        this.L0Counts = new ubyte[L0CountsLength];

        // Calculate the L1To8CountsLength and countsLength
        this.layers = L0CountsLength == 0 ? 0 : 1;

        ulong L1To8CountsLength = 0;
        ulong L9To24CountsLength = 0;
        ulong L25AndAboveLength = 0;
        ulong size = L0CountsLength/2;
        while(size >= 2) {
            if(layers >= 9 && layers <= 24) {
                L9To24CountsLength += size;
            } else if(layers <= 8) {
                L1To8CountsLength += size;
            } else {
                L25AndAboveLength += size;
            }
            size >>>= 1;
            layers++;
        }

        this.L1To8Counts = new ushort[L1To8CountsLength];
        this.L9To24Counts = new uint[L9To24CountsLength];
        this.L25AndAboveCounts = new ulong[L25AndAboveLength];

        // Propagate the old counts up the tree 
        if(propagateRequired) {
            propagateTree();
        } 
    }
    /** Iterate up the tree from the bottom, populating the counts of the upper tree nodes */
    void propagateTree() {
        // There are no tree counts
        if(L0Counts.length == 0) return;

        // Write popcnts into layer 0
        assert(L0Counts.length == bits.length);
        foreach(i; 0..L0Counts.length) {
            uint pc = popcnt(bits[i]);
            assert(pc <= 64);
            L0Counts[i] = pc.as!ubyte;
        }

        // Propagate the counts up the tree
        ulong destSize = L0Counts.length >>> 1;
        uint srcLayer = 0;
        ulong src, dest;
        while(destSize >= 2) {
            switch(srcLayer) {
                case 0: {
                    // L0Counts to L1To8Counts
                    dest = L1To8Counts.length - destSize;
                    foreach(i; 0..destSize) {
                        L1To8Counts[dest + i] = L0Counts[i*2] + L0Counts[i*2 + 1];
                    }
                    break;
                }
                case 1: .. case 7: {
                    // L1To8Counts to L1To8Counts
                    src  = dest;
                    dest -= destSize;
                    foreach(i; 0..destSize) {
                        uint v = L1To8Counts[src + i*2] + L1To8Counts[src + i*2 + 1];
                        assert(v <= ushort.max);
                        L1To8Counts[dest + i] = v.as!ushort;
                    }
                    break;
                }
                case 8: {
                    // L1To8Counts to L9To24Counts 
                    src  = dest;
                    assert(src == 0);
                    dest = L9To24Counts.length - destSize;
                    foreach(i; 0..destSize) {
                        L9To24Counts[dest + i] = L1To8Counts[src + i*2] + L1To8Counts[src + i*2 + 1];
                    }
                    break;
                }
                case 9: .. case 23: {
                    // L9To24Counts to L9To24Counts 
                    src  = dest;
                    dest -= destSize;
                    foreach(i; 0..destSize) {
                        L9To24Counts[dest + i] = L9To24Counts[src + i*2] + L9To24Counts[src + i*2 + 1];
                    }
                    break;
                }
                case 24:
                    // L9To24Counts to L25AndAboveCounts 
                    src  = dest;
                    assert(src == 0);
                    dest -= destSize;
                    foreach(i; 0..destSize) {
                        L25AndAboveCounts[dest + i] = L9To24Counts[src + i*2] + L9To24Counts[src + i*2 + 1];
                    }
                    break;
                default: {
                    // L25AndAboveCounts to L25AndAboveCounts 
                    src  = dest;
                    dest -= destSize;
                    foreach(i; 0..destSize) {
                        L25AndAboveCounts[dest + i] = L25AndAboveCounts[src + i*2] + L25AndAboveCounts[src + i*2 + 1];
                    }
                    break;
                }
            }
            srcLayer++;
            destSize >>>= 1;
        }
    }
    void updateCounts(ulong index, int add) {
        assert(add == 1 || add == -1);
        ulong indexDiv = index >>> 6;
        uint offset = 0;
        uint size   = 2;
        uint div    = capacityDiv;

        while(size < bits.length && offset < L25AndAboveCounts.length) { 
            L25AndAboveCounts[offset + (indexDiv >>> div)] += add.as!ulong;

            offset += size;
            size <<= 1;
            div--;
        }
        offset = 0;
        while(size < bits.length && offset < L9To24Counts.length) { 
            L9To24Counts[offset + (indexDiv >>> div)] += add.as!uint;

            offset += size;
            size <<= 1;
            div--;
        }
        offset = 0;
        while(size < bits.length) { 
            L1To8Counts[offset + (indexDiv >>> div)] += add.as!ushort;

            offset += size;
            size <<= 1;
            div--;
        }
        if(L0Counts.length > 0) {
            L0Counts[indexDiv] += add.as!ubyte;
        }
    }
    ulong sparseIndexOf(ulong index) {
        assert(index < capacity());

        ulong count      = 0;
        ulong treeOffset = 0;
        ulong size       = 2;
        uint shift       = capacityDiv;  
        ulong pivot      = bits.length >>> 1;
        ulong window     = bits.length >>> 2;

        ulong indexDiv = index >>> 6; 
        ulong indexRem = index & 63;
        uint layer     = layers-1;

        ulong getCount() {
            auto n = (pivot >>> shift) & ~1UL; 
            switch(layer) {
                case 0:
                    return L0Counts[n];
                case 1: .. case 8:
                    return L1To8Counts[treeOffset + n];
                case 9: .. case 24:
                    return L9To24Counts[treeOffset + n];
                default:
                    return L25AndAboveCounts[treeOffset + n];
            }
        }

        // Calculate counts
        while(size <= bits.length) {

            if(layer == 8 || layer == 24) {
                treeOffset = 0;
            }

            bool goRight = indexDiv >= pivot;

            if(goRight) {
                count += getCount();
                pivot += window;
            } else {
                pivot -= window;
            }

            treeOffset += size;
            size <<= 1;
            window >>>= 1;
            shift--;
            layer--;
        }

        // Add bits mask count
        ulong maskedBits = popcnt(bits[indexDiv] & (0x7fff_ffff_ffff_ffffUL >>> (63-indexRem)));
        count += maskedBits;

        return count;
    }
    T getItem(ulong index, T defaultValue = T.init) {
        if(index > capacity()) return defaultValue;
        if(!isBitSet(index)) return defaultValue;

        ulong sparseIndex = sparseIndexOf(index);
        if(sparseIndex < data.length) return data[sparseIndex];

        return defaultValue;
    }
    void addItem(ulong index, T value) {
        assert(index < capacity());
        assert(!isBitSet(index));

        setBit(index);
        updateCounts(index, 1);

        // Update the data array
        ulong sparse = sparseIndexOf(index);
        data.insertAt(sparse, value);
    }
    void removeItem(ulong index) {
        assert(index < capacity());
        assert(isBitSet(index));

        clearBit(index);
        updateCounts(index, -1);

        // Update the data array
        ulong sparse = sparseIndexOf(index);
        data.removeAt(sparse);
    }
    void replaceItem(ulong index, T value) {
        assert(index < capacity());
        assert(isBitSet(index));

        ulong sparseIndex = sparseIndexOf(index);
        assert(sparseIndex < data.length);
        data[sparseIndex] = value;
    }
}
