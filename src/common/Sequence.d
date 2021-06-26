module common.Sequence;

import common.all;

struct Sequence(T) if(isInteger!T) {
    private T value = T.init;

    T next() {
        return value++;
    }
}