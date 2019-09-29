module common.utils.utilities;

import common.all;

pragma(inline,true)
void expect(bool b, string file=__FILE__, int line=__LINE__) {
    if(unlikely(!b)) {
        import std.stdio : stderr;

        stderr.writefln("Expectation FAILED --> %s Line %s", file, line);
        flushConsole();

        throw new Error("Expectation FAILED --> %s Line %s".format(file, line));
    }
}
pragma(inline,true)
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
    assert(false, msg);
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

StopWatch startTiming() {
    StopWatch w;
    w.start();
    return w;
}
float millis(ref StopWatch watch) {
    return watch.peek().total!"nsecs"/1_000_000.0;
}

pragma(inline, true)
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

pragma(inline, true) {
int toInt(float f) pure nothrow { return cast(int)f; }
int toFloat(int i) pure nothrow { return cast(float)i; }
}

wstring[] getCommandLineArgs() {
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
}

// finds the next highest power of 2 for a 32 bit int
uint nextHighestPowerOf2(uint v) pure nothrow {
   v--;
   v |= v >> 1;
   v |= v >> 2;
   v |= v >> 4;
   v |= v >> 8;
   v |= v >> 16;
   v++;
   return v;
}

pragma(inline, true)
bool isPowerOf2(uint v) pure nothrow {
   return !(v & (v - 1)) && v;
}
pragma(inline, true)
bool isPowerOf2(ulong v) pure nothrow {
   return !(v & (v - 1)) && v;
}

pragma(inline, true)
T bitcast(T)(double from) {
    T* p =cast(T*)&from;
    return *p;
}

pragma(inline, true)
T bitcast(T)(ulong from) {
    T* p =cast(T*)&from;
    return *p;
}

pragma(inline, true)
T as(T,I)(I o) { return cast(T)o; }

pragma(inline, true)
bool isA(T,I)(I o) if(isObject!T && isObject!I) { return cast(T)o !is null; }

template FQN(string moduleName) {
    mixin("import FQN = " ~ moduleName ~ ";");
}
template From(string moduleName) {
    mixin("import From = " ~ moduleName ~ ";");
}

pragma(inline, true)
T firstNotNull(T)(T[] array...) if(isObject!T) {
    foreach(t; array) {
        if(t !is null) return t;
    }
    return null;
}

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