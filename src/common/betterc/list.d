module common.betterc.list;

public:
extern(C):
@nogc:
nothrow:

/**
 *  A dynamic array list using c-lib malloc,realloc and free.
 */
struct List(T) {
@nogc:
nothrow:
private:
    T* _ptr;
    int _length;
    int arrayLength;
public:
    T* ptr()     { return _ptr; }
    int length() { return _length; }

    static List!T make(int capacity) {
        //assert(capacity>=0);
        List!T list;
        if(capacity>0) {
            list.arrayLength = capacity;
            list._ptr        = cast(T*)malloc(list.arrayLength*T.sizeof);
        }
        return list;
    }
    void reset() {
        free(_ptr);
        _ptr = null;
        _length = 0;
        arrayLength = 0;
    }
    List!T copy() {
        List!T list = make(_length);
        for(auto i=0; i<_length; i++) {
            list._ptr[i] = _ptr[i];
        }
        list._length = _length;
        return list;
    }

    auto add(T value) {
        grow(1);
        _ptr[_length++] = value;
        return this;
    }
    auto add(T[] values...) {
        grow(values.length);
        for(auto i=0; i<values.length; i++) {
            _ptr[_length++] = values[i];
        }
        return this;
    }
    auto add(List!T values) {
        if(values.length>0) {
            grow(values.length);

            for(auto i=0; i<values._length; i++) {
                _ptr[i+_length++] = values._ptr[i];
            }
        }
        return this;
    }
    int count(T value) {
        int c = 0;
        for(auto i = 0; i<_length; i++) {
            if(_ptr[i]==value) c++;
        }
        return c;
    }
    /**
     *  list.each((v) { });
     */
    void each(void delegate(T v) nothrow @nogc functor) {
        for(auto i = 0; i<_length; i++) {
            functor(_ptr[i]);
        }
    }
    /**
     *  list.each((v,i) { });
     */
    void each(void delegate(T v, int index) nothrow @nogc functor) {
        for(auto i = 0; i<_length; i++) {
            functor(_ptr[i], i);
        }
    }
    /** 
     *  list.filter(v=>v<5) // ==> returns new List!T
     *      .each((v,i){});
     */
    auto filter(bool delegate(T v) nothrow @nogc functor) {
        List!T temp = make(_length);
        for(auto i = 0; i<_length; i++) {
            if(functor(_ptr[i])) {
                temp.add(_ptr[i]);
            }
        }
        return temp;
    }
    /** 
     *  list.map(v=>return v*2f);
     */
    auto map(K)(K delegate(T v) nothrow @nogc functor) {
        List!K temp = List!K.make(_length);
        for(auto i = 0; i<_length; i++) {
            auto v = functor(_ptr[i]);
            temp.add(v);
        }
        return temp;
    }
private:
    void grow(int count) {
        if(count==0) {
            // do nothing
        } else if(_ptr is null) {
            arrayLength = count+4;
            _ptr = cast(T*)malloc(arrayLength*T.sizeof);
        } else if(_length+count > arrayLength) {
            arrayLength = (arrayLength + count)*2;
            _ptr = cast(T*)realloc(_ptr, arrayLength*T.sizeof);
        }
    }
}

// struct Stream(T) {

// }