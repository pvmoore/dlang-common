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
 * Capacity   | Num bytes used
 * -----------|----------------|
 * 1,024      | 368            |
 * 2,048      | 752            |
 * 4,096      | 1,520          |
 * 8,192      | 3,056          |
 * 16,384     | 6,128          |
 * 65,536     | 24,560         |
 * 1,048,576  | 393,200        |
 * 2,097,152  | 786,416        |
 * 4,194,304  | 1,572,848      |
 * 8,388,608  | 3,145,712      |
 * 16,777,216 | 6,291,440      |
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
        return bits.length*8 + countsTree.length*8;
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

        // Update the counts if there are any
        if(countsTree.length > 0) {
            ulong indexDiv = index >>> 6;
            uint offset    = 0;
            uint num       = 2;
            uint div       = capacityDiv;

            while(num <= bits.length) { 
                ulong v = indexDiv >>> div;

                countsTree[offset+v]++;

                offset += num;
                num <<= 1;
                div--;
            }
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

        // Update the counts if there are any
        if(countsTree.length > 0) {
            ulong indexDiv = index >>> 6;
            uint offset    = 0;
            uint num       = 2;
            uint div       = capacityDiv;

            while(num <= bits.length) { 
                ulong v = indexDiv >>> div;

                countsTree[offset+v]--;

                offset += num;
                num <<= 1;
                div--;
            }
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

        // Calculate count from countsTree
        while(size <= bits.length) {

            bool goRight = indexDiv >= pivot;

            if(goRight) {
                auto n     = (pivot >>> shift) & ~1UL; 
                auto value = countsTree[treeOffset + n];
                count += value;
                pivot += window;
            } else {
                pivot -= window;
            }

            treeOffset += size;
            size <<= 1;
            window >>>= 1;
            shift--;
        }

        // Add bits mask count
        ulong maskedBits = popcnt(bits[indexDiv] & (0x7fff_ffff_ffff_ffffUL >>> (63-indexRem)));
        count += maskedBits;

        return count;
    }
    void clear() {
        _numItems = 0;
        countsTree = null;
        bits = null;
    }
    void dump() {
        writefln("┌───────────────────────────────────────────────────────────────────────────");
        writefln("│ numItems = %s, capacity = %s, (%s bytes used)", _numItems, bits.length*64, numBytesUsed());
        
        if(countsTree.length > 0) {
            writefln("│ COUNTS (%s):", countsTree.length);
            uint num = 2;
            uint prev = 0;
            while(num <= bits.length) {
                writef("│ [%2s] ", prev);
                foreach(i; prev..prev+num) {
                    writef(" %s", countsTree[i]);
                }
                writefln("");
                prev += num;
                num <<= 1;
            }
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
    //uint[] layer9To24Counts;

    // Layer [8] = max 32768 (64*512)
    // Layer [7] = max 16384 (64*256
    // Layer [6] = max 8192  (64*128)     
    // Layer [5] = max 4096  (64*64)
    // Layer [4] = max 2048  (64*32)
    // Layer [3] = max 1024  (64*16)
    // Layer [2] = max 512   (64*8)
    // Layer [1] = max 256   (64*4)
    //ushort[] layer1To8Counts;

    // Layer [0] = max 128 (64*2)
    //ubyte[] layer0Counts;


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
        bits.length = newCapacity >>> 6;

        this.capacityDiv = bsf(bits.length) - 1; 

        // Calculate the new countsTree length
        uint countsLength = 0;
        uint num = 2;
        while(num <= bits.length) {
            countsLength += num;
            num <<= 1;
        }

        // Create a new tree on the heap
        this.countsTree = new ulong[countsLength];

        // Propagate the old counts up the tree 
        if(propagateRequired) {
            propagateTree();
        } 
    }
    /** Iterate up the tree from the bottom, populating the counts of the upper tree nodes */
    void propagateTree() {
        // There are no tree counts
        if(bits.length == 0) return;

        // Write popcnts into the bottom layer
        foreach(i; 0..bits.length) {
            countsTree[countsTree.length-bits.length+i] = popcnt(bits[i]);
        }

        // There are no upper tree layers
        if(bits.length <= 2) return;

        // Propagate the counts to the upper tree layers
        ulong size      = bits.length >>> 1;
        ulong srcIndex  = countsTree.length - bits.length;
        ulong destIndex = srcIndex - size;

        while(size > 1) {
            foreach(i; 0..size) {
                countsTree[destIndex+i] = countsTree[srcIndex + i*2] + countsTree[srcIndex+1 + i*2];
            }
            size    >>>= 1;
            srcIndex   = destIndex;
            destIndex -= size; 
        }
    }
}
