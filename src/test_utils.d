module test_utils;

import std : writefln, writeln, format;

import common.all;

void testUtils() {
    testArrayUtils();
    testAsyncUtils();
    testCpuUtils();
    testStaticUtils();
    testStringUtils();
    testUtilities();
}

void testArrayUtils() {
    writefln("--== Testing array_utils ==--");

}
void testAsyncUtils() {
    writefln("Testing async_utils ...");

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


    writefln("OK");
}
void testStringUtils() {
    writefln("--== Testing string_utils ==--");

    string s1 = "hello";
    auto r1   = s1.removeChars('l');
    assert(s1=="hello");
    assert(r1=="heo");

    char[] s2 = ['h','e','l','l','o'];
    auto r2   = s2.removeChars('l');
    assert(s2==['h','e','l','l','o']);
    assert(r2==['h','e', 'o']);

    const(char)[] s3 = ['h','e','l','l','o'];
    auto r3          = s3.removeChars('l');
    assert(s3==['h','e','l','l','o']);
    assert(r3==['h','e', 'o']);
}
void testUtilities() {
    writefln("========--\nTesting utilities\n==--");

    // bitcast
    double d = 37.554;
    ulong l  = d.bitcastTo!ulong;
    double d2 = l.bitcastTo!double;
    writefln("d=%s, l=%s, d2=%s", d,l,d2);

    assert(bitcastTo!ulong(37.554).bitcastTo!double==37.554);

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

    writeln("testUtilities ran OK");
}