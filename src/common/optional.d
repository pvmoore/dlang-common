module common.optional;

import common.all;

/**
 * Opt!uint data;
 *
 * data = opt(data2);
 *
 * if(data.exists) {}
 *
 * auto value = data.orElse(0);
 *
 * data.let(it=>{
 *
 * });
 */
struct Opt(T)
    if(isStruct!T || isPrimitiveType!T)
{
    T value;
    bool exists;

    this(T value) {
        this.value = value;
        exists = true;
    }
    T orElse(T other) {
        return exists ? value : other;
    }
    void let(void delegate(T value) functor) {
        functor(value);
    }
}

Opt!T opt(T)(T value) if(isStruct!T || isPrimitiveType!T) {
    return Opt!T(value);
}
