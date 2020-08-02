module common.containers.SparseArray;

import common.all;

/**
 *  A fixed length array that is expected to be mostly empty.
 *
 */
final class SparseArray(T) {
private:
    ulong length;

public:
    ulong numItems;

    this(ulong length) {
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