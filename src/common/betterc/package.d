module common.betterc;

public:

import common.betterc.array;
import common.betterc.list;
import common.betterc.stream;

T as(T)(T thing) {
    return cast(T)thing;
}

