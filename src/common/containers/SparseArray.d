module common.containers.SparseArray;

import common.all;

/**
 *  A fixed length array that is expected to be mostly empty.
 *  The length must be a power of 2
 *
 *  32^1 =            32
 *  32^2 =         1,024
 *  32^3 =        32,768
 *  32^4 =     1,048,576
 *  32^5 =    33,554,432
 *  32^6 = 1,073,741,824   (64^3 = 262,144) (128^3 = 2,097,152) (256^3=16,777,216)
 *
 *  Example with length 256 = (8*32 bits)
 *
 *         0     0       0        0        0        0        0     | L1 Bits   (8*8 bits)
 *         0     0       0        0        0        0        0     | L1 Counts (8*16 bits)
 *   -     -     -       -        -        -        -        -     | L0 Bits   (8 * 32 bits)
 *   =     =     =       =        =        =        =        =     | L0 Counts (8 * 16 bits)
 * 0..31 32..63 64..95 96..127 128..159 160..191 192..223 224..255 |
 *
 * add(32, T)
 * add(162, T)
 *               0 | Increase counts diagonally up and right
 *             0 1 |
 *           0 1 0 |
 *         0 1 0 0 |
 *       0 1 0 0 0 |
 *     0 1 0 0 0 1 |
 *   0 1 0 0 0 1 0 |
 * - - T - - T - - | Values
 * 0 1 2 3 4 5 6 7 |
 *
 *               0 | L0 (0..31)  Increase counts diagonally up and right
 *               1 | L1
 *               0 | L2
 *               0 | L3
 *               1 | L4
 *               0 | L5
 *               0 | L6
 * - - T - - T - - | Values
 * 0 1 2 3 4 5 6 7 |
 */
final class SparseArray(T) {
private:
    ulong length;
    T[] values;

public:
    ulong numItems;

    this(ulong length) {
        assert(length>0);
        assert(isPowerOf2(length));
        this.length = length;
    }
    auto set(ulong index, T value) {

        return this;
    }
    ref T get(ulong index) {
        return T.init;
    }
    void clear() {
        this.numItems = 0;
    }
}