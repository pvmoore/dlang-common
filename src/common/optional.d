module common.optional;

import common.all;

/**
 * optional!uint data;
 * optional!uint data2 = 42;
 *
 * data = optional!uint(data2);
 *
 * if(data.isPresent()) {}
 *
 * auto value = data.orElse(0);
 *
 * data.ifPresent((it) {
 *
 * });
 * 
 */
struct optional(T)
    if(isStruct!T || isPrimitiveType!T)
{
public:
    static optional!T empty() { optional!T o; return o; }

    this(T value) {
        this._value = value;
        this._exists = true;
    }

    /** return true if the value is present */
    bool isPresent() { return _exists; }

    /** return the value (if present) otherwise will return T.init */
    T get() { return _value; }

    /** return the value (if present) otherwise will return other */
    T orElse(T other) {
        return _exists ? _value : other;
    }

    /** return the value (if present) otherwise will return compute() */
    T orElseCompute(T delegate() compute) {
        return _exists ? _value : compute();        
    }

    /** call the delegate if the value is present */
    void ifPresent(void delegate(T value) functor) {
        if(_exists) functor(_value);
    }

    /** map value to another optional by calling the delegate (if present) otherwise return an empty optional of the new type */
    optional!U map(U)(U delegate(T value) mapper) {
        if(_exists) return optional!U(mapper(_value));
        return optional!U.empty();
    }
private:
    T _value;
    bool _exists;
}

/**
 * auto t = firstOrElse([o1,o2], o3);
 */
T firstOrElse(T)(T[] objs, T other) if(isObject!T || isPointer!T || isSomeString!T || isDelegate!T) {
    foreach(o; objs) {
        if(o !is null) return o;
    }
    return other;
}

/**
 * auto t = firstOrElse([o,o1], o2);
 */
V firstOrElse(T = optional!V, V)(T[] opts, V other) if(isStruct!V || isPrimitiveType!V) {
    foreach(o; opts) {
        if(o.isPresent()) return o.get();
    }
    return other;
}



/**
 *  auto t = obj.orElse("this");
 */
T orElse(T)(T t, T other) if(isObject!T || isPointer!T || isSomeString!T || isDelegate!T) {
    return t !is null ? t : other;
}
