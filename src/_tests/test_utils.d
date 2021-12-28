module _tests.test_utils;

import std : writefln, writeln, format;

import common.all;

void testUtils() {
    testArrayUtils();
    testAsyncUtils();
    testCpuUtils();
    testStaticUtils();
    testStringUtils();
    testUtilities();
    testAsmUtils();
}

void testArrayUtils() {
    writefln("--== Testing array_utils ==--");

    { // contains
        uint[] a = [1,2,3,4];
        assert(a.contains(1));
        assert(a.contains(2));
        assert(a.contains(3));
        assert(a.contains(4));
        assert(!a.contains(5));
    }
    { // indexOf
        float[] a = [1,2,3];
        assert(a.indexOf(1) == 0);
        assert(a.indexOf(2) == 1);
        assert(a.indexOf(3) == 2);
        assert(a.indexOf(4) == -1);
    }
    { // insertAt
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
        a.insertAt(1, [8,7]);
        assert(a==[0,8,7,4,1,2,3,9]);
    }
    { // onlyContains
        uint[] a = [1,1,1];
        uint[] b = [0,0,1];
        assert(a.onlyContains(1));
        assert(!b.onlyContains(0));
    }
    { // push
        uint[] a = [1,2,3];
        a.push(4);
        assert(a == [1,2,3,4]);
    }
    { // pop
        uint[] a = [1,2];
        assert(2 == a.pop());
        assert(a==[1]);
        assert(1==a.pop());
        assert(a==[]);
        assert(uint.init == a.pop());
        assert(a==[]);
    }
     { // remove
        ubyte[] a = [1,2,3,4,5];
        assert(1 == a.remove(1));
        assert(a == [2,3,4,5]);
        assert(ubyte.init == a.remove(0));
        assert(a== [2,3,4,5]);
        assert(5 == a.remove(5));
        assert(a == [2,3,4]);
        assert(3 == a.remove(3));
        assert(a == [2,4]);
    }
    { // removeAt
        ubyte[] a = [1,2,3];
        assert(1 == a.removeAt(0));
        assert(a == [2,3]);
        assert(3 == a.removeAt(1));
        assert(a == [2]);
        assert(2 == a.removeAt(0));
        assert(a == []);
    }
    { // removeRange
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
    {   // add(T,U)(T[], U[])
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

    {
        writefln("bitfieldExtract(uint, uint, uint)");
        uint bits = 0b11111111_00000000_11001100_00110011;

        assert(bitfieldExtract(bits, 0, 4) == 0b0011);
        assert(bitfieldExtract(bits, 0, 8) == 0b00110011);
        assert(bitfieldExtract(bits, 2, 8) == 0b00001100);
        assert(bitfieldExtract(bits, 3, 8) == 0b10000110);
        assert(bitfieldExtract(bits, 5, 1) == 0b1);
        assert(bitfieldExtract(bits, 6, 1) == 0b0);
        assert(bitfieldExtract(bits, 6, 0) == 0b0);

        assert(bitfieldExtract(bits, 0, 32) == bits);
        assert(bitfieldExtract(bits, 0, 100) == bits);
        assert(bitfieldExtract(bits, 1, 100) == bits >>> 1);
    }
    {
        writefln("bitfieldExtract(ubyte[], uint, uint)");

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

    writeln("testUtilities ran OK");
}
void testAsmUtils() {
    writefln("========--\nTesting asm utils\n==--");

    struct _4 { float a,b,c,d; }
    struct _8 { float a,b,c,d,e,f,g,h; }

    {
        _4 a = _4(0,1,2,3);
        float b = 4;

        asm pure nothrow @nogc {
            movups XMM0, [RBP+a];
        }

        dumpXMMfloat(0);

        asm pure nothrow @nogc {
            movss XMM0, [RBP+b];
        }

        dumpXMMfloat(0);
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
}