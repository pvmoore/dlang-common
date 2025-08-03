module _tests.test_utils;

import std : writefln, writeln, format, iota;

import common.all;
import _tests.test : RUN_SUBSET;

void testUtils() {
    static if(RUN_SUBSET) {
    
    } else {
        testAsmUtils();
        testBitUtils();
        testArrayUtils();
        testMapUtils();
        testAsyncUtils();
        testCpuUtils();
        testStaticUtils();
        testStringUtils();
        testUtilities();
        testRangeUtils();
    }
}

void testMapUtils() {
    writefln("--== Testing map_utils ==--");

    import std : sort;

    alias Entry = Tuple!(ulong,uint);

    {   // entries
        uint[ulong] map = [
            4:2,
            7:3,
            1:10,
            5:25,
            3:7
        ];
        auto e = map.entries!(ulong,uint)();
        alias comp = (x,y) => x[1] > y[1];
        auto sorted = e.sort!(comp)().array;

        writefln("sorted = %s", sorted);
        assert(sorted == [
            Entry(5,25),
            Entry(1,10),
            Entry(3,7),
            Entry(7,3),
            Entry(4,2)
        ]);
    }
    {   // entriesSorted
        uint[ulong] map = [
            4:2,
            7:3,
            1:10,
            5:25,
            3:7
        ];
        auto sorted = map.entriesSorted!(ulong,uint)((a,b)=>a[1]>b[1]);
        writefln("sorted = %s", sorted);
        assert(sorted == [
            Entry(5,25),
            Entry(1,10),
            Entry(3,7),
            Entry(7,3),
            Entry(4,2)
        ]);
    }
    {
        // entriesSortedByKey
        uint[ulong] map = [
            4:2,
            7:3,
            1:10,
            5:25,
            3:7
        ];
        auto sortedAsc = map.entriesSortedByKey(true);
        writefln("sortedAsc = %s", sortedAsc);
        assert(sortedAsc == [
            Entry(1,10),
            Entry(3,7),
            Entry(4,2),
            Entry(5,25),
            Entry(7,3)
        ]);

        auto sortedDesc = map.entriesSortedByKey(false);
        writefln("sortedDesc = %s", sortedDesc);
        assert(sortedDesc == [
            Entry(7,3),
            Entry(5,25),
            Entry(4,2),
            Entry(3,7),
            Entry(1,10)
        ]);
    }
    {
        // entriesSortedByValue
        uint[ulong] map = [
            4:2,
            7:3,
            1:10,
            5:25,
            3:7
        ];
        auto sortedAsc = map.entriesSortedByValue(true);
        writefln("sortedAsc = %s", sortedAsc);
        assert(sortedAsc == [
            Entry(4,2),
            Entry(7,3),
            Entry(3,7),
            Entry(1,10),
            Entry(5,25)
        ]);

        auto sortedDesc = map.entriesSortedByValue(false);
        writefln("sortedDesc = %s", sortedDesc);
        assert(sortedDesc == [
            Entry(5,25),
            Entry(1,10),
            Entry(3,7),
            Entry(7,3),
            Entry(4,2)
        ]);
    }
}

void testArrayUtils() {
    writefln("--== Testing array_utils ==--");

    {
        writefln("- first()");
        uint[] a = [1,2,3];
        assert(a.first() == 1);

        string[] b = ["1","2"];
        assert(b.first() == "1");

        immutable(ubyte)[] c = [1,2,3];
        assert(c.first() == 1);
    }
    {
        writefln("- last()");

        uint[] a = [1,2,3];
        assert(a.last() == 3);

        string[] b = ["1","2"];
        assert(b.last() == "2");
    }
    {
        writefln("- isEmpty");
        uint[] a;
        assert(a.isEmpty());
        assert([].isEmpty());

        uint[] b = [1,2,3];
        assert(!b.isEmpty());
    }
    { 
        writefln("- contains");
        uint[] a = [1,2,3,4];
        assert(a.contains(1));
        assert(a.contains(2));
        assert(a.contains(3));
        assert(a.contains(4));
        assert(!a.contains(5));
    }
    { 
        writefln("- onlyContains");
        uint[] a = [1,1,1];
        uint[] b = [0,0,1];
        assert(a.onlyContains(1));
        assert(!b.onlyContains(0));
    }
    { 
        writefln("- indexOf");
        float[] a = [1,2,3];
        assert(a.indexOf(1) == 0);
        assert(a.indexOf(2) == 1);
        assert(a.indexOf(3) == 2);
        assert(a.indexOf(4) == -1);
    }
    { 
        writefln("- insertAt(T)");
        ubyte[] a;
        a.insertAt(0, 1);
        assert(a==[1]);
        a.insertAt(1, 2);
        assert(a==[1,2]);
        a.insertAt(2, 3);
        assert(a==[1,2,3]);
        a.insertAt(0, 0);
        assert(a == [0,1,2,3]);
        a.insertAt(1, 4);
        assert(a == [0,4,1,2,3]);
        a.insertAt(5,9);
        assert(a==[0,4,1,2,3,9]);
    }
    {
        writefln("- insertAt(T[])");
        int[] a = [1,2,3,4];

        a.insertAt(1, [8,7]);
        assert(a==[1,8,7,2,3,4]);

        a.insertAt(6, [9])
         .insertAt(7, [10,11]);
        assert(a==[1,8,7,2,3,4,9,10,11]);
    }
    {
        writefln("- replaceAt(T[])");
        int[] a = [1,2,3,4,5];
        a.replaceAt(0, [6,7]);
        assert(a == [6,7,3,4,5]);

        a.replaceAt(1, [8,9]);
        assert(a == [6,8,9,4,5]);

        a.replaceAt(3, [10]);
        assert(a == [6,8,9,10,5]);

        a.replaceAt(1, [11,12,13])  // [6,11,12,13,5]
         .replaceAt(2, [14,15]);    // [6,11,14,15,5]

        assert(a == [6,11,14,15,5]);
    }
    { 
        writefln("- push(T)");
        uint[] a = [1,2,3];
        a.push(4)
         .push(5);
        assert(a == [1,2,3,4,5]);
    }
    { 
        writefln("- pop(T)");
        uint[] a = [1,2];
        assert(2 == a.pop());
        assert(a==[1]);
        assert(1==a.pop());
        assert(a==[]);
        assert(uint.init == a.pop());
        assert(a==[]);
    }
     { 
        writefln("- remove");
        ubyte[] a = [1,2,3,4,5];
        assert(1 == a.remove(1));
        assert(a == [2,3,4,5]);

        assert(ubyte.init == a.remove(0));
        assert(99 == a.remove(0, 99));

        assert(a== [2,3,4,5]);
        assert(5 == a.remove(5));
        assert(a == [2,3,4]);
        assert(3 == a.remove(3));
        assert(a == [2,4]);
    }
    { 
        writefln("- removeAt");
        ubyte[] a = [1,2,3];
        assert(1 == a.removeAt(0));
        assert(a == [2,3]);
        assert(3 == a.removeAt(1));
        assert(a == [2]);
        assert(2 == a.removeAt(0));
        assert(a == []);

        uint[] b = [1,2,3,4,5];
        assert(1 == b.removeAt(0));
        assert(b == [2,3,4,5]);
        assert(5 == b.removeAt(3));
        assert(b == [2,3,4]);
        assert(3 == b.removeAt(1));
        assert(b == [2,4]);
    }
    {
        writefln("- removeFirstMatch");
        uint[] a = [1,2,3,4,5];

        assert(3 == a.removeFirstMatch!uint(it=> it == 3));
        assert(a == [1,2,4,5]);

        assert(4 == a.removeFirstMatch((uint it) { return it == 4; }));
        assert(a == [1,2,5]);

        assert(0 == a.removeFirstMatch!uint((it) { return it == 7; }, 0));
        assert(a == [1,2,5]);   
    }
    { 
        writefln("- removeRange");
        ubyte[] a = [1,2,3,4,5,6,7,8,9];
        a.removeRange(0, 1);
        assert(a == [3,4,5,6,7,8,9]);
        a.removeRange(5, 6);
        assert(a == [3,4,5,6,7]);
        a.removeRange(1,1);
        assert(a == [3,5,6,7]);
        a.removeRange(1,2);
        assert(a==[3,7]);
    }
    {   
        writefln("- add");
        ubyte[] bytes = [cast(ubyte)0,1,2,3,4];
        uint[] ints = [5,6]; // 5,0,0,0,6,0,0,0
        short[] shorts = [7,8]; // 7,0,8,0

        bytes.add(ints);
        assert(bytes.length == 5 + 2*4);
        assert(bytes == [cast(ubyte)0,1,2,3,4, 5,0,0,0, 6,0,0,0]);

        bytes.add(shorts);
        assert(bytes.length == 13 + 2*2);
        assert(bytes == [cast(ubyte)0,1,2,3,4, 5,0,0,0, 6,0,0,0, 7,0,8,0]);
    }
}
void testAsyncUtils() {
    writefln("Testing async_utils ...");

    {
        auto t = new Thread( () {
            writefln("\tT1 thread ID   = %s", Thread.getThis.id);
        } );
        t.start();

        Thread.sleep(dur!"msecs"(500));

        writefln("\tMain thread ID = %s", Thread.getThis.id);
        writefln("\tChecking ...");

        auto t2 = new Thread( () {
            writefln("\tT2 thread ID   = %s", Thread.getThis.id);

            /// This is bad
            //ast.check();

        } );
        t2.start();
        t2.join();
        t.join();
    }
    {
        Atomic!bool b0;
        auto b1 = Atomic!bool();
        auto b2 = Atomic!bool(true);
        assert(!b0.get());
        assert(!b1.get());
        assert(b2.get());

        b0.set(true);
        b1.set(true);
        b2.set(false);

        assert(b0.get());
        assert(b1.get());
        assert(!b2.get());

        b0.setAndRelease(false);
        assert(!b0.get());
        assert(!b0.getAndAcquire());

        b0.compareAndSet(false, true);
        assert(b0.get());

        b0.compareAndSet(true, false);
        assert(!b0.get());
    }
    {
        auto a = Atomic!uint(0);
        auto threads = iota(0, 10).map!(it=>new Thread(() { 

            Thread.sleep(dur!"msecs"(10));

            foreach(i; 0..10) {
                // inefficient increment to test compareAndSet functionality
                while(!a.compareAndSet(a.value, a.value+1)) {}
            }
        })).array;
        
        threads.each!((t) { t.start(); });

        threads.each!((t) { t.join(); });
        writefln("a.get() = %s", a.get());

        assert(a.get() == 10*10);
    }

    { // uint cas32(void* ptr, uint expected, uint newValue)
        uint a = 30;

        uint old = cas32(&a, 30, 31);
        writefln("a = %s", a);
        throwIf(old != 30);
        uint old2 = cas32(&a, 31, 32);
        throwIf(old2 != 31);
    }
    { // ulong cas64(void* ptr, ulong expected, ulong newValue)
        ulong a = 30;

        ulong old = cas64(&a, 30, 31);
        writefln("a = %s", a);
        throwIf(old != 30);
        ulong old2 = cas64(&a, 31, 32);
        throwIf(old2 != 31);
    }
    {   // uint atomicSet32(void* ptr, uint newValue)
        // uint atomicGet32(void* ptr) 
        uint a = 0;
        uint old = atomicSet32(&a, 9);
        uint b = atomicGet32(&a);
        writefln("a = %s, old = %s, b = %s", a, old, b);
        throwIf(a != 9);
        throwIf(old != 0);
        throwIf(b != 9);
    }
    {   // ulong atomicSet64(void* ptr, ulong newValue)
        // ulong atomicGet64(void* ptr) 
        ulong a = 0;
        ulong old = atomicSet64(&a, 9);
        ulong b = atomicGet64(&a);
        writefln("a = %s, old = %s", a, old);
        throwIf(a != 9);
        throwIf(old != 0);
        throwIf(b != 9);
    }
    {   // void atomicAdd32(void* ptr, uint add) 
        uint a = 5;
        atomicAdd32(&a, 3);
        writefln("a = %s", a);
    }
    {   // void atomicAdd64(void* ptr, ulong add) 
        ulong a = 5;
        atomicAdd64(&a, 3);
        writefln("a = %s", a);
    }
    {
        // mfence()
        // sfence()
        // lfence()
        mfence();
        sfence();
        lfence();
    }
}
void testCpuUtils() {
    writefln("Testing cpu_utils ...");

    uint features = getAVX512Support();

    writefln("features = %s", toString!AVX512Feature(features, null, null));
}
void testStaticUtils() {
    writefln("Testing static_utils ...");

    class A {
        int foo;

        void bar(int a) {}
        void bar(float a) {}
        int bar(bool a) { return 0; }
    }

    assert(hasProperty!(A,"foo"));
    assert(!hasProperty!(A,"bar"));

    assert(hasProperty!(A,"foo",int));
    assert(!hasProperty!(A,"foo",bool));

    assert(hasMethodWithName!(A,"bar"));
    assert(!hasMethodWithName!(A,"foo"));

    assert(hasMethod!(A,"bar", void, int));
    assert(hasMethod!(A,"bar", void, float));
    assert(hasMethod!(A,"bar", int, bool));

    assert(!hasMethod!(A,"bar", void, int, int));
    assert(!hasMethod!(A,"bar", void, bool));

    {
        writefln("isInteger");
        assert(isInteger!byte);
        assert(isInteger!ubyte);
        assert(isInteger!short);
        assert(isInteger!ushort);
        assert(isInteger!int);
        assert(isInteger!uint);
        assert(isInteger!long);
        assert(isInteger!ulong);
        assert(!isInteger!float);
        assert(!isInteger!double);
        assert(!isInteger!string);
    }
    {
        writefln("isEnum");

        enum E1 { ONE, TWO }

        assert(isEnum!E1);
        assert(!isEnum!int);
    }
    struct B {
        int foo;
        int bar;
        int baz;

        this(int foo, int bar, int baz) {
            this.foo = foo;
            this.bar = bar;
            this.baz = baz;
        }
        ~this() {}
        void fn1() {}
        int fn2(int a) { return a; }
    }
    class C {
        int foo;
        int bar;
        int baz;

        this(int foo, int bar, int baz) {
            this.foo = foo;
            this.bar = bar;
            this.baz = baz;
        }
        ~this() {}
        void fn1() {}
        int fn2(int a) { return a; }
    }
    final class D : C {
        this(int foo, int bar, int baz) {
            super(foo, bar, baz);
        }
    }
    {
        writefln(" getAllProperties()");
        
        string[] props = getAllProperties!(B);
        assert(props.length == 3);
        foreach(p; props) {
            writefln("\t%s", p);
        }
        assert(props.contains("foo"));
        assert(props.contains("bar"));
        assert(props.contains("baz"));

        string[] props2 = getAllProperties!(C);
        assert(props2.length == 3);
        foreach(p; props2) {
            writefln("\t%s", p);
        }
        assert(props2.contains("foo"));
        assert(props2.contains("bar"));
        assert(props2.contains("baz"));
    }
    {
        writefln(" getAllFunctions()");

        string[] bFuncs = getAllFunctions!(B);
        writefln("B functions:");
        foreach(p; bFuncs) {
            writefln("\t%s", p);
        }
        assert(bFuncs.contains("fn1"));
        assert(bFuncs.contains("fn2"));
        // May also contain "opAssign"

        string[] cFuncs = getAllFunctions!(C);
        writefln("C functions:");
        foreach(p; cFuncs) {
            writefln("\t%s", p);
        }
        assert(cFuncs.contains("fn1"));
        assert(cFuncs.contains("fn2"));
        // May also contain "toString", "opEquals", "opCmp", "toHash"

        string[] dFuncs = getAllFunctions!(D);
        writefln("D functions:");
        foreach(p; dFuncs) {
            writefln("\t%s", p);
        }
        assert(dFuncs.contains("fn1"));
        assert(dFuncs.contains("fn2"));
        // May also contain "toString", "opEquals", "opCmp", "toHash"
    }


    writefln("OK");
}
void testStringUtils() {
    writefln("--== Testing string_utils ==--");

    {
        string s1 = "hello";
        auto r1   = s1.removeChars('l');
        assert(s1=="hello");
        assert(r1=="heo");
    }
    {
        char[] s2 = ['h','e','l','l','o'];
        auto r2   = s2.removeChars('l');
        assert(s2==['h','e','l','l','o']);
        assert(r2==['h','e', 'o']);
    }
    {
        const(char)[] s3 = ['h','e','l','l','o'];
        auto r3          = s3.removeChars('l');
        assert(s3==['h','e','l','l','o']);
        assert(r3==['h','e', 'o']);
    }
    {   // getPrefix
        auto s = "hello_there";
        assert(s.getPrefix("_") == "hello");
        assert(s.getPrefix("-") == "");
        assert(s.getPrefix(null) == "");

        string s2 = null;
        assert(s2.getPrefix("_") == "");
    }
    {   // getSuffix
        auto s = "hello_there";
        assert(s.getSuffix("_") == "there");
        assert(s.getSuffix("--",) == "");
        assert(s.getSuffix(null) == "");

        string s2 = null;
        assert(s2.getSuffix("_") == "");
    }
    {   // getPrefixAndSuffix
        auto s = "hello_there";
        auto t = s.getPrefixAndSuffix("_");
        assert(t[0] == "hello" && t[1] == "there");

        auto t2 = s.getPrefixAndSuffix("wah");
        assert(t2[0] == "" && t2[1] == "");
    }
    {
        // containsAny
        assert("hello".containsAny("ll"));
        assert(!"hello".containsAny("a", "aa"));
        assert("hello".containsAny("a", "lo"));
        assert("hello".containsAny("this", "hello"));
    }
    {
        // capitalised
        assert("Hello" == capitalised("hello"));
        assert(".." == "..".capitalised());
        assert("" == "".capitalised());
        assert(null is capitalised(cast(string)null));
    }
}
void testUtilities() {
    writefln("========--\nTesting utilities\n==--");

    // isObject
    class MyClass {}
    writefln("%s", isObject!MyClass);

    // as
    class A {}
    interface I {}
    class B : A,I {}

    auto o0 = new A;
    auto o1 = new B;
    I o2 = o1;

    assert(o0.as!A !is null);
    assert(o1.as!A !is null);
    assert(o2.as!A !is null);

    assert(o0.as!B is null);
    assert(o1.as!B !is null);
    assert(o2.as!B !is null);

    assert(o0.as!I is null);
    assert(o1.as!I !is null);
    assert(o2.as!I !is null);

    assert((3.14).as!int == 3);

    {   // className
        string n = className!MyClass;
        writefln("className = %s", n);
        assert(n == "MyClass");

        string n2 = className(new MyClass());
        writefln("className = %s", n2);
        assert(n == "MyClass");
    }

    { // isA
        class AA {}
        interface II {}
        class BB : II {}
        auto a = new AA;
        auto b = new BB;
        II i = b;
        assert(a.isA!AA);
        assert(b.isA!BB);
        assert(i.isA!II);
        assert(i.isA!BB);
        assert(! i.isA!AA);
    }

    {   /// onlyContains
        ubyte[] b0 = [];
        assert(false == onlyContains(b0.ptr, b0.length, 0));
        assert(false == onlyContains(b0.ptr, b0.length, 1));

        ubyte[] b1 = [0];
        assert(false == onlyContains(b1.ptr, b1.length, 1));
        assert(true  == onlyContains(b1.ptr, b1.length, 0));

        ubyte[] b2 = [0,0,0,0,0,0,0,0];
        assert(true  == onlyContains(b2.ptr, b2.length, 0));
        assert(false == onlyContains(b2.ptr, b2.length, 1));

        ubyte[] b3 = [0,0,0,1,0,0,0,0];
        assert(false == onlyContains(b3.ptr, b3.length, 0));

        ubyte[] b4 = [0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0];
        ubyte[] b5 = [0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
        assert(true  == onlyContains(b4.ptr, b4.length, 0));
        assert(false == onlyContains(b5.ptr, b5.length, 0));
    }

    // firstNotNull
    {
        auto a = new Object;
        Object b = null;
        assert(firstNotNull!Object(null, b, a) is a);
    }

    // visit
    bool visitedA, visitedB;
    class Visited {
        void visit(A a) { visitedA=true; }
        void visit(B b) { visitedB=true; }
    }
    auto a = new A;
    auto b = new B;
    auto v = new Visited();

    a.visit(v);
    assert(visitedA && !visitedB);
    visitedA = visitedB = false;

    b.visit(v);
    assert(!visitedA && visitedB);

    {
        enum E1 { A, B }
        enum E2 : uint { A, B }

        assert(1.isSet(1));

        assert(1.isSet(E1.B));
        assert(1.isSet(E2.B));

        assert(0.isUnset(1));
        assert(0.isUnset(E1.B));
        assert(0.isUnset(E2.B));
    }

    { // let
        Object obj = new Object;
        obj.let!Object((o) {});
        let!Object(obj, (o) {});

        obj.let!Object(o=>writefln("%s", o));
    }
    {   // getAlignedValue
        assert(getAlignedValue(0, 4) == 0);
        assert(getAlignedValue(1, 4) == 4);
        assert(getAlignedValue(3, 4) == 4);
        assert(getAlignedValue(4, 4) == 4);
        assert(getAlignedValue(0, 8) == 0);
        assert(getAlignedValue(1, 8) == 8);
        assert(getAlignedValue(7, 8) == 8);
        assert(getAlignedValue(8, 8) == 8);
        assert(getAlignedValue(9, 8) == 16);
    }

    writeln("testUtilities ran OK");
}
void testAsmUtils() {
    writefln("========--\nTesting asm utils\n==--");

    version(LDC) {
        writefln("LDC");

        align(32) double[4] ymmd;
        ymmd = [3.14, 1.0, 7.5, 10.9];
        setYMM!4(ymmd);
        dumpYMM!(double,4)();

        align(32) float[8] ymmf;
        ymmf = [3579123.14, 4.14, 5.14, 6.14, 7.14, 8.14, 9.14, 10.14];
        setYMM!4(ymmf);
        dumpYMM!(float,4)();

        align(32) long[4] ymml = [1,2,3,4];
        setYMM!4(ymml);
        dumpYMM!(long,4);

        align(32) int[8] ymmi = [1,2,3,4,5,6,7,8];
        setYMM!4(ymmi);
        dumpYMM!(int,4);

        align(32) short[16] ymms = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16];
        setYMM!4(ymms);
        dumpYMM!(short,4);

        align(32) byte[32] ymmb = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                                17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32];
        setYMM!4(ymmb);
        dumpYMM!(byte,4);

        getYMM!(long,0)(ymml);
        setYMM!4(ymml);
        dumpYMM!(long,4);

        {   // bextr
            ulong a = 0xff00_0102_0304_0506; 

            throwIf(bextr(&a, 0, 8) != 0x06);
            throwIf(bextr(&a, 8, 8) != 0x05);
            throwIf(bextr(&a, 16, 8) != 0x04);
            throwIf(bextr(&a, 8, 16) != 0x0405);

            throwIf(bextr(a, 0, 8) != 0x06);
            throwIf(bextr(a, 8, 8) != 0x05);
            throwIf(bextr(a, 16, 8) != 0x04);
            throwIf(bextr(a, 8, 16) != 0x0405);
        }
        {   // pext
            ulong a = 0b11101010;
            throwIf(pext(a, 0b11) != 0b10);
            throwIf(pext(a, 0b11111111) != 0b11101010);

            ulong mask = 0b11;
            ulong mask2 = 0b11111111;
            throwIf(pext(a, &mask) != 0b10);
            throwIf(pext(a, &mask2) != 0b11101010);
        }
        {   // pdep
            ulong a = 0b11001010;
            ulong mask = 0b1111_11110000;
            throwIf(pdep(a, 0b1111_11110000) != 0b110010100000);
            throwIf(pdep(a, &mask) != 0b110010100000);

        }
    } // version(LDC)
    else version(DigitalMars) {

    struct _4 { float a,b,c,d; }
    struct _8 { float a,b,c,d,e,f,g,h; }

    {
        _4 a = _4(0,1,2,3);
        float b = 4;

        asm pure nothrow @nogc {
            movups XMM0, [RBP+a];
        }

        dumpYMMfloat(0);

        asm pure nothrow @nogc {
            movss XMM0, [RBP+b];
        }

        dumpYMMfloat(0);
    }

    {
        _8 a = _8(0,1,2,3,4,5,6,7);
        float b = 5;

        asm pure nothrow @nogc {
            vmovups YMM0, [RBP+a];
        }

        dumpYMMfloat(0);

        asm pure nothrow @nogc {
            // upper 4 floats will be zeroed
            movss XMM0, [RBP+b];
        }

        dumpYMMfloat(0);
    }
    } // version(DigitalMars) 
}
void testRangeUtils() {
    writefln("----------------------------------------------------------------");
    writefln(" Testing range utils");
    writefln("----------------------------------------------------------------");
    {
        writefln(" frontOrElse()");
        int[] r = [1,2,3,4];

        assert(4 == r.filter!(it=>it > 3).frontOrElse(0));
        assert(0 == r.filter!(it=>it > 4).frontOrElse(0));
    }
    {
        writefln(" Range examples:");
        final class ClassWithInputRange {
            uint[] values;
 
            auto inputRange() {
                struct InputRange {
                    uint[] values;
                    ulong i;
                    uint front() { return values[i]; }
                    bool empty() { return i >= values.length; }
                    void popFront() { i++; }
                }
                return InputRange(values); 
            }
            auto forwardRange() {
                struct ForwardRange {
                    uint[] values;
                    ulong i;
                    uint front() { return values[i]; }
                    bool empty() { return i >= values.length; }
                    void popFront() { i++; }
                    auto save() { return ForwardRange(values, i); }
                }
                return ForwardRange(values); 
            }
            auto bidirectionalRange() {
                struct BidirectionalRange {
                    uint[] values;
                    ulong i;    
                    ulong u;    
                    uint front() { return values[i]; }
                    uint back() { return values[u-1]; }
                    bool empty() { return i < u; }
                    void popFront() { i++; }
                    void popBack() { u--; }
                    auto save() { return BidirectionalRange(values, i, u); }
                }
                return BidirectionalRange(values, 0, values.length); 
            }
            auto randomAccessRange() {
                struct RandomAccessRange {
                    uint[] values;
                    ulong i;
                    ulong u;
                    uint front() { return values[i]; }
                    uint back() { return values[u-1]; }
                    bool empty() { return i < u; }
                    void popFront() { i++; }
                    void popBack() { u--; }
                    auto save() { return RandomAccessRange(values, i, u); }
                    uint opIndex(ulong i) { return values[i]; }
                    ulong length() { return values.length; }
                }
                return RandomAccessRange(values, 0, values.length); 
            }

        }

        import std.range.primitives;

        auto c = new ClassWithInputRange();
        assert(isInputRange!(typeof(c.inputRange())));
        assert(isForwardRange!(typeof(c.forwardRange())));
        assert(isBidirectionalRange!(typeof(c.bidirectionalRange())));
        assert(isRandomAccessRange!(typeof(c.randomAccessRange())));

        c.values = [1,2,3,4,5];
        foreach(v; c.inputRange()) {
            writefln("v = %d", v);
        }
        foreach(v; c.forwardRange()) {
            writefln("v = %d", v);
        }
    }
    {
        writefln(" Sorting");
        auto r = [1,2,3,4,5,6,7,8,9,10];
        
        // Sort in place
        r.sort!((a,b) => a > b);
        assert(r == [10,9,8,7,6,5,4,3,2,1]);

        // Return sorted range
        auto sortedRange = r.sort!((a,b) => a < b);
        auto s = sortedRange.array;
        assert(s == [1,2,3,4,5,6,7,8,9,10]);

        // Sort using inferred comparison function
        auto r2 = [8,9,10,7,4,5,6,3,1,2];
        r2.sort();
        assert(r2 == [1,2,3,4,5,6,7,8,9,10]);
    }
    {
        // Note that 'uniq' only works on consecutive unique elements so the input is expected to be sorted
        writefln(" Uniq");
        import std.algorithm : uniq;
        auto r = [1,2,1,3,4,5,2,6,7,7,8,9,10,7,8];
        writefln("uniq = %s", r.sort().uniq().array);
        assert(r.sort().uniq().array == [1,2,3,4,5,6,7,8,9,10]);        
    }

}
void testBitUtils() {
    writefln("========--\nTesting bit utils\n==--");  

    {
        writefln(" - bitCount");
        assert(bitCount(0) == 0);
        assert(bitCount(1) == 1);
        assert(bitCount(2) == 1);
        assert(bitCount(3) == 2);
        assert(bitCount(4) == 1);
        assert(bitCount(5) == 2);
        assert(bitCount(255) == 8);

        assert(bitCount(cast(ulong)0b1111_1111) == 8);

        enum E1 {
            ZERO = 0,
            ONE = 1,
            TWO = 2,
            THREE = 3
        }
        assert(bitCount(E1.THREE) == 2);
    }
    {
        writefln(" - nextHighestPowerOf2");
        assert(nextHighestPowerOf2(1) == 1);
        assert(nextHighestPowerOf2(2) == 2);
        assert(nextHighestPowerOf2(3) == 4);
        assert(nextHighestPowerOf2(4) == 4);
        assert(nextHighestPowerOf2(5) == 8);
        assert(nextHighestPowerOf2(250) == 256);
        assert(nextHighestPowerOf2(4611686022722355456UL) == 9223372036854775808UL);
    }   
    {
        writefln(" - isPowerOf2");
        assert(isPowerOf2(1));
        assert(isPowerOf2(2));
        assert(!isPowerOf2(3));
        assert(isPowerOf2(4));
        assert(!isPowerOf2(5));
        assert(!isPowerOf2(250));
        assert(isPowerOf2(1UL << 63));
        assert(!isPowerOf2(1UL << 63 | 1UL));
    }
    enum Flags {
        A = 1,
        B = 2,
        C = 4,
        D = 8,
    }
    {
        writefln(" - isSet");
        assert(isSet(0b1000, 8));
        assert(!isSet(0b1000, 2));
        assert(isSet(8, Flags.D));
        assert(!isSet(8, Flags.B));
        assert(isSet(Flags.A, 1));
        assert(!isSet(Flags.A, 2));
    }
    {
        writefln(" - isUnset");
        assert(isUnset(0b1000, 2));
        assert(!isUnset(0b1000, 8));
        assert(isUnset(8, Flags.B));
        assert(!isUnset(4, Flags.C));
        assert(isUnset(Flags.A, 2));
        assert(!isUnset(Flags.A, 1));
    }
    {
        writefln(" - getAlignedValue");
        assert(getAlignedValue(0, 4) == 0);
        assert(getAlignedValue(1, 4) == 4);
        assert(getAlignedValue(2, 4) == 4);
        assert(getAlignedValue(3, 4) == 4);
        assert(getAlignedValue(4, 4) == 4);
        assert(getAlignedValue(5, 4) == 8);
        assert(getAlignedValue(6, 16) == 16);
        assert(getAlignedValue(15, 16) == 16);
        assert(getAlignedValue(16, 16) == 16);
        assert(getAlignedValue(17, 16) == 32);
    }
    {
        writefln(" - bitcastTo");
        double d = 37.554;
        ulong l  = d.bitcastTo!ulong;
        double d2 = l.bitcastTo!double;
        writefln("d=%s, l=%s, d2=%s", d,l,d2);

        assert(bitcastTo!ulong(37.554).bitcastTo!double==37.554);
    }
    {
        writefln(" - bitfieldExtract(T,uint,uint)");
        ubyte a = 0b00001011;
        assert(bitfieldExtract(a, 0, 2) == 0b11);
        assert(bitfieldExtract(a, 1, 2) == 0b01);

        uint b = 0b10110110_00110010;
        //                ^
        //                |
        //                8
        assert(bitfieldExtract(b, 0, 4) == 0b0010);
        assert(bitfieldExtract(b, 3, 4) == 0b0110);
        assert(bitfieldExtract(b, 7, 3) == 0b100);
        assert(bitfieldExtract(b, 11, 5) == 0b10110);
        assert(bitfieldExtract(b, 11, 6) == 0b010110);
        assert(bitfieldExtract(b, 11, 7) == 0b0010110);
        assert(bitfieldExtract(b, 11, 8) == 0b00010110);
        assert(bitfieldExtract(0b10110110_00110010, 3, 5) == 0b0_00110);

        ulong c = 0b10110110_00110010_00000000_01101010_00000000_00000000_00000000_00000000;
        //                                            ^
        //                                            |
        //                                            32
        assert(bitfieldExtract(c, 33, 8) == 0b0_0110101);

        assert(bitfieldExtract(cast(uint)10, 0, 33) == 10);

        uint bits2 = 0b11111111_00000000_11001100_00110011;

        assert(bitfieldExtract(bits2, 0, 4) == 0b0011);
        assert(bitfieldExtract(bits2, 0, 8) == 0b00110011);
        assert(bitfieldExtract(bits2, 2, 8) == 0b00001100);
        assert(bitfieldExtract(bits2, 3, 8) == 0b10000110);
        assert(bitfieldExtract(bits2, 5, 1) == 0b1);
        assert(bitfieldExtract(bits2, 6, 1) == 0b0);
        assert(bitfieldExtract(bits2, 6, 0) == 0b0);

        assert(bitfieldExtract(bits2, 0, 32) == bits2);
        assert(bitfieldExtract(bits2, 0, 100) == bits2);
        assert(bitfieldExtract(bits2, 1, 100) == bits2 >>> 1);
    }
    {
        writefln("- bitfieldExtract(ubyte[], uint, uint)");

        ubyte[] bits = [
            0b01100101, 0b11110000, // 0  - 15
            0b11001100, 0b01010101, // 16 - 31
            0b11111111, 0b00001111, // 32 - 47
            0b00110011, 0b10101010  // 48 - 63
        ];

        assert(bitfieldExtract(bits, 0, 0) == 0);
        assert(bitfieldExtract(bits, 0, 4) == 0b0101);
        assert(bitfieldExtract(bits, 0, 8) == 0b01100101);
        assert(bitfieldExtract(bits, 0, 14) == 0b110000_01100101);

        assert(bitfieldExtract(bits, 1, 4) == 0b0010);
        assert(bitfieldExtract(bits, 1, 8) == 0b00110010);
        assert(bitfieldExtract(bits, 1, 12) == 0b1000_00110010);
        assert(bitfieldExtract(bits, 1, 16) == 0b01111000_00110010);
        assert(bitfieldExtract(bits, 1, 19) == 0b11001111000_00110010);
        assert(bitfieldExtract(bits, 1, 21) == 0b00110_01111000_00110010);
        assert(bitfieldExtract(bits, 1, 24) == 0b11100110_01111000_00110010);
        assert(bitfieldExtract(bits, 1, 27) == 0b010_11100110_01111000_00110010);
        assert(bitfieldExtract(bits, 1, 30) == 0b101010_11100110_01111000_00110010);
        assert(bitfieldExtract(bits, 1, 32) == 0b1_01010101_11001100_11110000_0110010_);

        assert(bitfieldExtract(bits, 9, 10) == 0b_1001111000);

        assert(bitfieldExtract(bits, 30, 4) == 0b1101);
    }
}
