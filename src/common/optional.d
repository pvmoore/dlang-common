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
struct optional(T) {
public:
    static optional!T empty() { optional!T o; return o; }

    this(T value) {
        this._value = value;
        static if(!isNullable!T) {
            this._exists = true;
        }
    }

    /** return true if the value is present */
    bool isPresent() { 
        static if(isNullable!T) {
            return _value !is null;
        } else {
            return _exists; 
        }
    }

    /** return the value (if present) otherwise will return T.init */
    T get() { return _value; }

    /** return the value (if present) otherwise will return other */
    T orElse(T other) {
        return isPresent() ? _value : other;
    }

    /** return the value (if present) otherwise will return compute() */
    T orElseCompute(T delegate() compute) {
        return isPresent() ? _value : compute();        
    }

    /** call the delegate if the value is present */
    void ifPresent(void delegate(T value) functor) {
        if(isPresent()) functor(_value);
    }

    /** call the delegate if the value is not present */
    void ifNotPresent(void delegate() functor) {
        if(!isPresent()) functor();
    }

    /** filter value by calling the delegate (if present) otherwise return an empty optional */
    optional!T filter(bool delegate(T value) predicate) {
        if(isPresent() && predicate(_value)) return optional!T(_value);
        return optional!T.empty();
    }

    /** map value to another optional by calling the delegate (if present) otherwise return an empty optional of the new type */
    optional!U map(U)(U delegate(T value) mapper) {
        if(isPresent()) return optional!U(mapper(_value));
        return optional!U.empty();
    }
private:
    T _value;
    static if(!isNullable!T) {
    bool _exists;
    }
}

/**
 * optional!int o1 = 1;
 * optional!int o2 = 2;
 * int o3 = 3;
 *
 * auto t = firstOrElse([o1, o2], o3);
 */
V firstOrElse(T : optional!V, V)(T[] opts, V other)  {
    foreach(o; opts) {
        if(o.isPresent()) return o.get();
    }
    return other;
}

/**
 * class A{} 
 * A o1;
 * A o2;
 * A o3 = new A();
 *
 * auto t = firstOrElse([o1, o2], o3);
 */
T firstOrElse(T)(T[] objs, T other) if(isNullable!T) {
    foreach(o; objs) {
        if(o !is null) return o;
    }
    return other;
}

/**
 *  auto t = obj.orElse("this");
 */
T orElse(T)(T t, T other) if(isNullable!T) {
    return t !is null ? t : other;
}
