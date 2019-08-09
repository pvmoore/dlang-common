module common.betterc.array;

public:
extern(C):
@nogc:
nothrow:

/**
 *  An array with a compile-time known fixed capacity.
 *  Elements can be added and removed as long as the capacity is not exceeded.
 */
struct Array(T,int CAPACITY) {
@nogc:
nothrow:
private:
    alias ARRAY = Array!(T,CAPACITY);
    T[CAPACITY] array;
    int _length;
public:
    T* ptr()     { return array.ptr; }
    int length() { return _length; }

    extern(D)
    int opApply(int delegate(T) @nogc nothrow dg) {
        int result = 0;
        for(auto i=0; i<_length; i++) {
            result = dg(array[i]);
            if(result) break;
        }
        return result;
    }
    void reset() {
        _length = 0;
    }
    ARRAY copy() {
        ARRAY list;
        for(auto i=0; i<_length; i++) {
            list.array[i] = array[i];
        }
        list._length = _length;
        return list;
    }

    auto add(T value) {
        array[_length++] = value;
        return this;
    }
    auto add(T[] values...) {
        for(auto i=0; i<values.length; i++) {
            array[_length++] = values[i];
        }
        return this;
    }
    auto add(L)(L values) {
        for(auto i=0; i<values._length; i++) {
            array[i+_length++] = values.array[i];
        }
        return this;
    }
    int count(T value) {
        int c = 0;
        for(auto i = 0; i<_length; i++) {
            if(array[i]==value) c++;
        }
        return c;
    }
    /**
     *  list.each((v) { });
     */
    void each(void delegate(T v) nothrow @nogc functor) {
        for(auto i = 0; i<_length; i++) {
            functor(array[i]);
        }
    }
    /**
     *  list.each((v,i) { });
     */
    void each(void delegate(T v, int index) nothrow @nogc functor) {
        for(auto i = 0; i<_length; i++) {
            functor(array[i], i);
        }
    }
    /**
     *  list.filter(v=>v<5) // ==> returns new List!T
     *      .each((v,i){});
     */
    auto filter(bool delegate(T v) nothrow @nogc functor) {
        ARRAY temp;
        for(auto i = 0; i<_length; i++) {
            if(functor(array[i])) {
                temp.add(array[i]);
            }
        }
        return temp;
    }
    /**
     *  list.map(v=>return v*2f);
     */
    auto map(K)(K delegate(T v) nothrow @nogc functor) {
        Array!(K,CAPACITY) temp;
        for(auto i = 0; i<_length; i++) {
            auto v = functor(array[i]);
            temp.add(v);
        }
        return temp;
    }
}