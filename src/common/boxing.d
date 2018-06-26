module common.boxing;

import common.all;

final class Boxed(T) {
    T value;
    this(T value) {
        this.value = value;
    }
}

