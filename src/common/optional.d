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
 * data.let((it) {
 *
 * });
 */
struct Opt(T)
    if(isStruct!T || isPrimitiveType!T)
{
public:
    bool exists() { return _exists; }
    T value() { return _value; }

    this(T value) {
        this._value = value;
        this._exists = true;
    }
    T orElse(T other) {
        return _exists ? _value : other;
    }
    void let(void delegate(T value) functor) {
        functor(_value);
    }
private:
    T _value;
    bool _exists;
}

/**
 * Opt!uint a;
 * assert(!a.exists);
 * a = opt(22);
 * assert(a.exists);
 */
Opt!T opt(T)(T value) if(isStruct!T || isPrimitiveType!T) {
    return Opt!T(value);
}

/**
 * auto t = firstOrElse([o,o1], o2);
 */
T firstOrElse(T)(Opt!(T)[] opts, T other) {
    foreach(o; opts) {
        if(o.exists) return o.value;
    }
    return other;
}

/**
 * auto t = firstOrElse([o1,o2], o3);
 */
T firstOrElse(T)(T[] objs, T other) if(__traits(compiles, "other is null")) {
    foreach(o; objs) {
        if(o !is null) return o;
    }
    return other;
}

/**
 *  auto t = obj.orElse("this");
 */
T orElse(T)(T t, T other) if(__traits(compiles, "other is null")) {
    return t !is null ? t : other;
}
