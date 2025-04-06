module common.allocators.SparseArrayIndexes;

import common.all;
import core.bitop : bsf, bsr, popcnt;

/**
 * SparseArrayIndexes keeps a record of positions of items in a sparsely populated array in a way that
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
 * A SparseArrayIndexes of capacity 1024 can hold up to 1024 item indexes. It is optimised to hold only a few
 * items so filling it up too much would be less efficient than just using a flat array. 
 * The indexes are used to lookup the actual item in a separate flat array which can be 
 * much smaller.
 *
 * ulong index = sparseArrayIndexes.sparseIndexOf(1000);
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
 * 1,024      | 368            | 256             | 172                 |
 * 2,048      | 752            | 528             | 348                 |
 * 4,096      | 1,520          | 1,072           | 700                 |    
 * 8,192      | 3,056          | 2,160           | 1,404               |
 * 16,384     | 6,128          | 4,336           | 2,812               |
 * 65,536     | 24,560         | 17,392          | 11,272              |
 * 2,097,152  | 786,416        | 557,040         | 361,200             |
 * 4,194,304  | 1,572,848      | 1,114,096       | 722,416             |
 * 8,388,608  | 3,145,712      | 2,228,208       | 1,444,848           |
 * 16,777,216 | 6,291,440      | 4,456,432       | 2,889,712           |
 */
final class SparseArrayIndexes {
public:
    bool isEmpty() {
        return _numItems == 0;
    }
    ulong numItems() {
        return _numItems; 
    }
    ulong capacity() {
        return bits.length * 64;
    }
    ulong numBytesUsed() {
        return bits.length*8 + countsTree.length*8 + L0Counts.length*1 + L1To8Counts.length*2;
    }

    this() {}
    this(ulong capacity) {
        assert(popcnt(capacity) == 1);
        expand(capacity-1);
    }
    /** 
     * Adds an index to the sparse array.
     */
    void add(ulong index) {
        if(index >= bits.length*64) expand(index);

        // We don't want to increase the counts more than once for the same index
        if(isBitSet(index)) return;

        // Update bits
        setBit(index);

        ulong indexDiv = index >>> 6;
        
        // Update the L1..n counts if there are any
        uint offset = 0;
        uint size   = 2;
        uint div    = capacityDiv;

        // Update countsTree (L9To24Counts)
        while(size < bits.length && offset < countsTree.length) { 
            ulong v = indexDiv >>> div;

            countsTree[offset + v]++;

            offset += size;
            size <<= 1;
            div--;
        }
        // Update L1To8Counts
        offset = 0;
        while(size < bits.length) { 
            ulong v = indexDiv >>> div;

            L1To8Counts[offset + v]++;

            offset += size;
            size <<= 1;
            div--;
        }
        // Update the layer0 counts if there are any
        if(L0Counts.length > 0) {
            L0Counts[indexDiv]++;
        }

        _numItems++;
    }
    /**
     * Removes an index from the sparse array.
     * Returns true if the index was removed or false if it was not found.
     */
    bool remove(ulong index) {
        // Ignore if index is out of range or not set
        if(index >= bits.length*64) return false;
        if(!isBitSet(index)) return false;

        // Update bits
        clearBit(index);

        ulong indexDiv = index >>> 6;
        
        // Update the L1..n counts if there are any
        uint offset    = 0;
        uint size       = 2;
        uint div       = capacityDiv;

        while(size < bits.length && offset < countsTree.length) { 
            ulong v = indexDiv >>> div;

            countsTree[offset+v]--;

            offset += size;
            size <<= 1;
            div--;
        }
        // Update L1To8Counts
        offset = 0;
        while(size < bits.length) { 
            ulong v = indexDiv >>> div;

            L1To8Counts[offset + v]--;

            offset += size;
            size <<= 1;
            div--;
        }
        // Update the layer0 counts if there are any
        if(L0Counts.length > 0) {
            L0Counts[indexDiv]--;
        }

        _numItems--;
        return true;
    }
    ulong sparseIndexOf(ulong index) {
        // Handle out of bounds
        if(index >= bits.length*64) return _numItems;

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
                    goto default;
                default:
                    return countsTree[treeOffset + n];
            }
        }

        // Calculate count from countsTree
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
    void clear() {
        _numItems = 0;
        layers = 0;
        countsTree = null;
        L0Counts = null;
        L1To8Counts = null;
        bits = null;
    }
    void dump() {
        writefln("┌───────────────────────────────────────────────────────────────────────────");
        writefln("│ numItems = %s, capacity = %s, (%s bytes used)", _numItems, bits.length*64, numBytesUsed());
        
        writefln("│ L9..n (%s):", countsTree.length);
        uint size = 2;
        ulong offset = 0;
        if(countsTree.length > 0) {
            while(offset < countsTree.length) {
                writef("│ [%2s] ", offset);
                foreach(i; offset..offset+size) {
                    writef(" %s", countsTree[i]);
                }
                writefln("");
                offset += size;
                size <<= 1;
            }
        }

        writefln("│ L1..8 (%s):", L1To8Counts.length);
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

        writefln("│ L0 (%s):", L0Counts.length);
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
        writefln("└───────────────────────────────────────────────────────────────────────────");
    }
private:
    ulong _numItems;    // Number of items added to the counts tree
    uint capacityDiv;   // bsf(capacity) - 1
    uint layers;

    // todo - this tree can be a ubyte[] and accessed using a ptr of the required size to save space
    // The bottom layer maximum is always 128 which can be ubytes
    // For 8 layers above that ushorts are enough to hold the counts
    // Layer maximum counts:
    // 
    // Layer [32] = 137438953472 ulong (64*2147483648)
    // Layer [31] = 68719476736 ulong  (64*1073741824)
    // Layer [28] = 34359738368 ulong (64*536870912) 
    // Layer [27] = 17179869184 ulong (64*268435456)
    // Layer [26] = 8589934592 ulong (64*134217728) 
    // Layer [25] = 4294967296 ulong (64*67108864)
    ulong[] countsTree;

    // Layer [24] = 2147483648 uint (64*33554432)
    // Layer [23] = 1073741824 uint (64*16777216) 
    // Layer [22] = 536870912 uint (64*8388608)
    // Layer [21] = 268435456 uint (64*4194304)
    // Layer [20] = 134217728 uint (64*2097152)
    // Layer [19] = 67108864 uint (64*1048576)
    // Layer [18] = 33554432 uint (64*524288)  
    // Layer [17] = 16777216 uint (64*262144)
    // Layer [16] = 8388608 uint (64*131072)
    // Layer [15] = 4194304 uint (64*65536)
    // Layer [14] = 2097152 uint (64*32768)
    // Layer [13] = 1048576 uint (64*16384)
    // Layer [12] = 524288 uint  (64*8192)
    // Layer [11] = 262144 uint  (64*4096)
    // Layer [10] = 131072 uint  (64*2048)
    // Layer [9]  = 65536 uint   (64*1024)
    //uint[] L9To24Counts;

    // Layer [8] = max 32768 (64*512)
    // Layer [7] = max 16384 (64*256
    // Layer [6] = max 8192  (64*128)     
    // Layer [5] = max 4096  (64*64)
    // Layer [4] = max 2048  (64*32)
    // Layer [3] = max 1024  (64*16)
    // Layer [2] = max 512   (64*8)
    // Layer [1] = max 256   (64*4)
    ushort[] L1To8Counts;

    // Layer [0] = max 128 (64*2)
    ubyte[] L0Counts;

    // todo- We can turn this into a sparse array using the bottom row of the counts tree
    //       to indicate whether a bits block is used or not
    ulong[] bits;

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
        ulong countsLength = 0;
        ulong size = L0CountsLength/2;
        while(size >= 2) {
            if(layers <= 8) {
                L1To8CountsLength += size;
            } else {
                countsLength += size;
            }
            size >>>= 1;
            layers++;
        }

        // writefln("capacity    = %s", capacity);
        // writefln("bits        = %s", bits.length);
        // writefln("layers      = %s", layers);
        // writefln("L0Counts    = %s", L0CountsLength);
        // writefln("L1To8Counts = %s", L1To8CountsLength);
        // writefln("counts      = %s", countsLength);

        // Create the L1To8Counts tree
        this.L1To8Counts = new ushort[L1To8CountsLength];

        // Create the L9To24Counts tree
        this.countsTree = new ulong[countsLength];

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
                    // L1To8Counts to layer9To24Counts 
                    dest = countsTree.length - destSize;
                    foreach(i; 0..destSize) {
                        countsTree[dest + i] = L1To8Counts[i*2] + L1To8Counts[i*2 + 1];
                    }
                    break;
                }
                case 9: .. case 24: {
                    // countsTree to countsTree 
                    src  = dest;
                    dest -= destSize;
                    foreach(i; 0..destSize) {
                        countsTree[dest + i] = countsTree[src + i*2] + countsTree[src + i*2 + 1];
                    }
                    break;
                }
                case 25:
                    // 
                    todo();
                    break;
                default: {
                    // 
                    todo();
                    break;
                }
            }
            srcLayer++;
            destSize >>>= 1;
        }
    }
}
