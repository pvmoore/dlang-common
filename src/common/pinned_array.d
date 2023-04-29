module common.pinned_array;

import common.all;
/**
 *  An array implementation which provides pinned memory
 *  which is guaranteed not to be realloced when the length
 *  changes.
 *
 *  todo - finish this
 */
final class PinnedArray(T) {
private:
    T[] arrays;

    static struct Chunk {
        T[] array;
        long len;
    }
public:
    long length;

    override string toString() {
        return "";
    }
    this(int initialSize) {

    }
    T opIndex(long i) {
        return T.init;
    }
	void opIndexAssign(ulong i, T val) {
		array[i] = val;
	}
//	T[] opIndex() {
//        return array[0..len];
//    }
//    T[] opSlice(ulong from, ulong to) {
//        return array[from..to];
//    }
	long opDollar() {
        return length;
    }
private:

}

