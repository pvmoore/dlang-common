module common.stringbuffer;
/**
 *
 */
import common.all;
import std.traits : isSomeChar;

alias StringBuffer  = StringBuffer_t!char;
alias WStringBuffer = StringBuffer_t!wchar;
alias DtringBuffer  = StringBuffer_t!dchar;

final class StringBuffer_t(T) if(isSomeChar!T) {
private:
    Array!T array;
public:
    ulong length() const { return array.length; }
    bool empty() const { return length==0; }

    this() {
        this.array = new Array!T;
    }
    this(inout(T)[] str) {
        this();
        add(str);
    }
    override string toString() const {
        return cast(string)array[0..array.length].idup;
    }
    bool opEquals(inout(T)[] o) const {
        return array[] == o;
    }
    override bool opEquals(Object o) const {
        auto other = cast(StringBuffer_t!T)o;
        return other !is null && array[] == other.array[];
    }
    //int opCmp(inout(T)[] o) {
    //    return array[].opCmp(o);
    //}
    //int opCmp(StringBuffer_t!T o) {
    //    return array[].opCmp(o.array[]);
    //}
    //T opBinary(string op)(inout(T)[] rhs) {
    //    static if(op == "=") {
    //        clear().add(rhs);
    //    }
    //    else static assert(0, "Operator "~op~" not implemented");
    //}
    void opOpAssign(string op)(T rhs) {
        static if(op=="~") {
            add(rhs);
            //mixin("this"~op~"rhs;");
        } else {
            static assert(0, "Operator "~op~" not implemented");
        }
    }
    void opOpAssign(string op)(inout(T)[] rhs) {
        static if(op=="~") {
            add(rhs);
            //mixin("this"~op~"rhs;");
        } else {
            static assert(0, "Operator "~op~" not implemented");
        }
    }
    auto add(T ch) {
        array.add(ch);
        return this;
    }
    auto add(inout(T)[] str) {
        array.add(cast(T[])str);
        return this;
    }
    auto add(A...)(inout(T)[] fmt, A args) {
        add(format(fmt, args));
        return this;
    }

    T opIndex(ulong i) const {
        return array[i];
    }
    immutable(T)[] opSlice() const {
        return array[];
    }
    immutable(T)[] opSlice(ulong from, ulong to) const {
        return array[from..to];
    }
    long opDollar() const {
        return array.length;
    }
    auto clear() {
        array.clear();
        return this;
    }
    int indexOf(T val) const {
        return array.indexOf(val);
    }
    int indexOf(inout(T)[] str) const {
        static import std.string;
        return cast(int)std.string.indexOf(array[], str);
    }
    bool contains(T val) const {
        return indexOf(val)!=-1;
    }
    bool contains(inout(T)[] str) const {
        static import std.string;
        return std.string.indexOf(array[], str) != -1;
    }
    auto insert(T ch, ulong index) {
        array.insertAt(index, ch);
        return this;
    }
    auto remove(ulong index) {
        array.removeAt(index);
        return this;
    }
private:

}

