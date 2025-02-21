module common.utils.utilities;

import common.utils;
import common.intrinsics        : unlikely;
import common.io                : flushConsole;
import std.datetime.stopwatch   : StopWatch;
import std.format               : format;

void expect(bool b, string file=__FILE__, int line=__LINE__) {
    if(unlikely(!b)) {
        import std.stdio : stderr;

        stderr.writefln("Expectation FAILED --> %s Line %s", file, line);
        flushConsole();

        throw new Error("Expectation FAILED --> %s Line %s".format(file, line));
    }
}
void expect(A...)(bool b, lazy string fmt, lazy A args) {
    if(unlikely(!b)) {
        import std.stdio : stderr;

        auto msg = format(fmt, args);

        stderr.writefln("Expectation FAILED --> %s", msg);
        flushConsole();

        throw new Error("Expectation FAILED --> %s".format(msg));
    }
}
void todo(string msg = "TODO - Not yet implemented") {
    throwIf(true, msg);
}

/**
 * Throw Exception if _result_ is true
 */
void throwIf(A...)(bool result, string msgFmt, A args) {
    if(result) throw new Exception(format(msgFmt, args));
}
void throwIfNot(A...)(bool result, string msgFmt, A args) {
    if(!result) throw new Exception(format(msgFmt, args));
}
void throwIfNull(A...)(inout void* result, string msgFmt, A args) {
    if(result is null) throw new Exception(format(msgFmt, args));
}
void throwIfNotNull(A...)(inout void* result, string msgFmt, A args) {
    if(result !is null) throw new Exception(format(msgFmt, args));
}

void throwIf(bool result) {
    throwIf(result, "Assertion failed");
}
void throwIfNot(bool result) {
    throwIf(!result, "Assertion failed");
}
void throwIfNull(inout void* obj) {
    throwIf(obj is null, "Expected object to be not null");
}
void throwIfNotNull(inout void* obj) {
    throwIf(obj !is null, "Expected object to be null");
}
void throwIfNotEqual(string a, string b) {
    if(a == b) return;
    throwIf(true, 
            "Expected strings to be the same but they are different:\n" ~
            "A: %s\n" ~
            "B: %s\n" ~
            "A: %s\n" ~
            "B: %s", a, b, cast(ubyte[])a, cast(ubyte[])b);
}

/**
 * Creates a property with optional public setter and getter.
 *   eg. mixin(property!(string, "myvariable", true, true));
 *      private string _myvariable;
 *      public string myvariable() { return _myvariable; }
 *      public void myvariable(string v) { this._myvariable = v; }
 */
template property(T, string name, bool getter = false, bool setter = false) {
    const property =
        "private %s _%s; ".format(T.stringof, name) ~
         (getter ? "public %s %s() { return _%s; } ".format(T.stringof, name, name) : "") ~
         (setter ? "public void %s(%s value) { this._%s = value; }".format(name, T.stringof, name) : "")
        ;
}
/**
 * eg. mixin(constructor!MyStruct)
 */
template constructor(T) {

}
/**
 * eg. mixin(addToString!MyStruct)
 */
template addToString(T) {
    // getAllProperties!T
    const addToString = "";
}

StopWatch startTiming() {
    StopWatch w;
    w.start();
    return w;
}
float millis(ref StopWatch watch) {
    return watch.peek().total!"nsecs"/1_000_000.0;
}

void swap(T)(ref T a, ref T b) pure nothrow {
	T temp = a;
	a = b;
	b = temp;
}
/// returns true if the entire array only contains values
bool onlyContains(void* ptr, ulong numBytes, ubyte value)  {
    if(numBytes==0) return false;
    if(numBytes>=8) {
        auto len8    = numBytes>>>3;
        ulong value8 = 0x01010101_01010101 * cast(ulong)value;
        ulong* p  = cast(ulong*)ptr;

        for(auto i=0; i<len8; i++) {
            if((*p++)!=value8) return false;
        }

        ptr      += (numBytes&~7);
        numBytes &= 7;
        if(numBytes==0) return true;
    }
    ubyte* p = cast(ubyte*)ptr;
    for(auto i=0; i<numBytes; i++) {
        if((*p++)!=value) return false;
    }
    return true;
}
/// Returns true if the mem at ptr[0..len] is 0
bool isZeroMem(void* ptr, ulong numBytes) nothrow {
    if(numBytes>=8) {
        auto len8 = numBytes>>>3;
        ulong* p  = cast(ulong*)ptr;
        for(auto i=0; i<len8; i++) {
            if(*p++) return false;
        }
        ptr += (numBytes&~7);
        numBytes &= 7;
        if(numBytes==0) return true;
    }
    ubyte* p = cast(ubyte*)ptr;
    for(auto i=0; i<numBytes; i++) {
        if(*p++) return false;
    }
    return true;
}

//int toInt(float f) pure nothrow { return cast(int)f; }
//int toFloat(int i) pure nothrow { return cast(float)i; }

wstring[] getCommandLineArgs() {
    version(Win64) {
        import core.sys.windows.windows :
            CommandLineToArgvW,
            GetCommandLineW;

        wchar* cmd = GetCommandLineW();
        int numArgs;
        wchar** argsArray = CommandLineToArgvW(cmd, &numArgs);
        wstring[] w;
        for(auto i=0; i<numArgs; i++) {
            w ~= fromWStringz(argsArray[i]);
        }
        return w;

    } else assert(false);
}

/**
 *  net.widget.Label -> "Label"
 */
string className(T)() if(isObject!T) {
    import std.string : lastIndexOf;
    string name = typeid(T).name;
    auto i = name.lastIndexOf('.');
    return i==-1 ? name : name[i+1..$];
}

string className(Object obj) {
    import std.string : lastIndexOf;
    string name = typeid(obj).name;
    auto i = name.lastIndexOf('.');
    return i==-1 ? name : name[i+1..$];
}

T as(T,I)(I o) { return cast(T)o; }

bool isA(T,I)(I o) if(isObject!T && isObject!I) { return cast(T)o !is null; }

template FQN(string moduleName) {
    mixin("import FQN = " ~ moduleName ~ ";");
}
template From(string moduleName) {
    mixin("import From = " ~ moduleName ~ ";");
}

bool isOneOf(T)(T thing, T[] args...) {
    foreach(a; args) if(a==thing) return true;
    return false;
}

T firstNotNull(T)(T[] array...) if(isObject!T || is(T==string)) {
    foreach(t; array) {
        if(t !is null) return t;
    }
    return null;
}

/**
 * Object o;
 * let((o) {});
 */
void let(T)(T receiver, void delegate(T thing) func) {
    if(receiver) func(receiver);
}

// size_t hashOf(T)(T v) if(isPrimitiveType!T) {
//     return cast(ulong)v;
// }
// size_t hashOf(T)(T v) if(isObject!T || isStruct!T) {
//     return v.toHash();
// }

/**
 *  Dynamic dispatch.
 *  eg.
 *      interface Thing {}
 *      class B : Thing {}
 *      class C : Thing {}
 *      class A {
 *          void visit(B b) {}
 *          void visit(C c) {}
 *      }
 *      A a;
 *      Thing thing;
 *      thing.visit!A(a)
 */
void visit(T)(Object o, T instance) {
    import std.traits : Parameters, fullyQualifiedName;
	const fqn = typeid(o).name;

    // use a string switch to select the correct function to call
	switch(fqn) {

	    static foreach(ov; __traits(getOverloads, T, "visit")) {
	        //alias FQN = fullyQualifiedName!(Parameters!ov[0]);

            mixin("case "~fullyQualifiedName!(Parameters!ov[0]).stringof~" : " ~
                  "    instance.visit(cast(Parameters!ov[0])o);" ~
                  "    return;");
        }
        default : throw new Error("visit(%s) not implemented".format(fqn));
	}
}
///
/// Accepts multiple extra arguments and
/// calls the defaultAction if the function is not found.
///
void dynamicDispatch(string FUNCNAME="visit", O, T, ARGS...)
                    (O o, T instance, void delegate(O) defaultAction, ARGS args)
{
    import std.traits : Parameters, fullyQualifiedName;
    const fqn = typeid(o).name;

    const NUM_ARGS = 1+args.length;

    // use a string switch to select the correct function to call
    switch(fqn) {

        static foreach(ov; __traits(getOverloads, T, FUNCNAME)) {
            static if (Parameters!ov.length==NUM_ARGS) {
                mixin("case "~fullyQualifiedName!(Parameters!ov[0]).stringof~" : " ~
                      "    instance.%s(cast(Parameters!ov[0])o, args);".format(FUNCNAME) ~
                      "    return;");
        }
        }
        default :
            defaultAction(o);
            break;
    }
}
R dynamicDispatchRet(string FUNCNAME="visit", O, R, T, ARGS...)
                    (O o, T instance, void delegate(O) defaultAction, ARGS args)
{
    import std.traits : Parameters, fullyQualifiedName;
    const fqn = typeid(o).name;

    const NUM_ARGS = 1+args.length;

    // use a string switch to select the correct function to call
    switch(fqn) {

        static foreach(ov; __traits(getOverloads, T, FUNCNAME)) {
            static if (Parameters!ov.length==NUM_ARGS) {
                mixin("case "~fullyQualifiedName!(Parameters!ov[0]).stringof~" : " ~
                "    return instance.%s(cast(Parameters!ov[0])o, args);".format(FUNCNAME));
            }
        }
        default :
            defaultAction(o);
            return R.init;
    }
}
//void visit(T)(Object o, T to) {
//    import std.traits : ParameterTypeTuple;
//	string fqn = typeid(o).name;
//
//	foreach(ov; __traits(getOverloads, T, "visit")) {
//		string paramFqn = typeid(ParameterTypeTuple!ov[0]).name;
//
//		if(fqn==paramFqn) {
//			to.visit(cast(ParameterTypeTuple!ov[0])o);
//			return;
//		}
//	}
//	import std.format:format;
//	throw new Error("visit(%s) not implemented".format(fqn));
//}


