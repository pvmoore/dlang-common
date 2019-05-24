
import std.stdio;
import common;
import core.stdc.stdlib : malloc, calloc;
import core.atomic      : atomicLoad, atomicStore, atomicOp;
import core.time        : dur;
import core.thread      : Thread, thread_joinAll;
import core.memory      : GC;

import std.random       : randomShuffle,uniform, Mt19937, unpredictableSeed;
import std.format       : format;
import std.conv         : to;
import std.typecons     : Tuple,tuple;
import std.range        : array,stride,join,iota;
import std.parallelism  : parallel, task;
import std.file         : exists, tempDir, remove;
import std.array        : join;
import std.datetime.stopwatch   : benchmark, StopWatch;
import std.algorithm.iteration  : permutations, map, sum, each;
import std.algorithm.sorting    : sort;
import std.algorithm.mutation   : reverse;

import test_async;

const RUN_SUBSET = false;

void main() {
    version(assert) {
        runTests();
        static if(!RUN_SUBSET) {
            runAsyncTests();
        }
    } else {
        writefln("Not running test in release mode");
    }
}
void runTests() {
    writefln("Running tests");
    scope(failure) writefln("-- FAIL");
    scope(success) writeln("-- OK - All standard tests finished\n");

    static if(RUN_SUBSET) {

    } else {
        testPDH();
        testQueue();
        testAllocator();
        testTreeList();
        testStructCache();
        testList();
        testSet();
        testArray();
        testUtilities();
        testStructCache();
        testObjectCache();
        testBool3();
        testStack();
        testByteReader();
        testByteWriter();
        testBitWriter();
        testBitReader();
        testBitReaderAndWriter();
        testArrayUtils();
        testStringUtils();
        testStringBuffer();
        testVelocity();
        testHasher();
        testConsole();
        testAsyncUtils();

        testPriorityQueue();
    }
}

void let(T)(T receiver, void delegate(T thing) func) {
    func(receiver);
}

void testAllocator() {
    writefln("--== Testing Allocator ==--");


    void testEmptyAllocator() {
        auto a = new Allocator_t!uint(0);
        expect(a.empty);
        expect(a.length==0);
        expect(a.numBytesFree==0);
        expect(a.numBytesUsed==0);
        expect(a.numFreeRegions==1);
        auto fr = a.freeRegions;
        expect(fr.length==1);
        expect(fr[0][0]==0 && fr[0][1]==0);
        expect(a.offsetOfLastAllocatedByte()==0);

        /// try to allocate 10
        expect(-1 == a.alloc(10));

        /// resize
        a.resize(100);
        expect(a.empty);
        expect(a.length==100);
        expect(a.numBytesFree==100);
        expect(a.numBytesUsed==0);
        expect(a.numFreeRegions==1);
        fr = a.freeRegions;
        expect(fr.length==1);
        expect(fr[0][0]==0 && fr[0][1]==100);
        expect(a.offsetOfLastAllocatedByte()==0);

        /// Allocate 10
        expect(0 == a.alloc(10));

        expect(!a.empty);
        expect(a.length==100);
        expect(a.numBytesFree==90);
        expect(a.numBytesUsed==10);
        expect(a.numFreeRegions==1);
        fr = a.freeRegions;
        expect(fr.length==1);
        expect(fr[0][0]==10 && fr[0][1]==90);
        expect(a.offsetOfLastAllocatedByte()==9);

        writefln("Empty Allocator OK");
    }
    void testFreeing() {
        auto a = new Allocator_t!uint(100);
        expect(0==a.alloc(50));
        expect(a.numFreeRegions==1);
        expect(a.offsetOfLastAllocatedByte()==49);
        // |xxxxx.....|

        a.free(10, 20);
        // |x..xx.....|
        expect(a.numBytesFree==70);
        expect(a.getFreeRegionsByOffset==[tuple(10,20), tuple(50,50)]);
        expect(a.offsetOfLastAllocatedByte()==49);

        a.free(40,10);
        // |x..x......|
        expect(a.numBytesFree==80);
        expect(a.getFreeRegionsByOffset==[tuple(10,20), tuple(40,60)]);
        expect(a.offsetOfLastAllocatedByte()==39);
    }
    testEmptyAllocator();
    testFreeing();


    struct Regn { uint offset, size; }
    // 0 represents free, 1 represents used
    ubyte[10_000] data;
    Regn[] allocked;

    auto at = new Allocator(data.length);
    //writefln("offset=%s", at.alloc(77,4));
    //writefln("offset=%s", at.alloc(8,1));
    //writefln("offset=%s", at.alloc(10,4));
    //writefln("offset=%s", at.alloc(11,1));
    //writefln("offset=%s", at.alloc(6, 4));
//    writefln("offset=%s", at.alloc(100));

//    writefln("offset=%s", at.alloc(10000));
//    at.free(0,1000);
//
//    writefln("------------");
//   at.free(1100,100);
   //at.free(10000-100,100);
   //at.free(10000-300,200);
    //at.free(300,100);
//    at.free(300,100);
//    at.free(400,100);
//
//    writefln("%s", at);
//    flushConsole();
//     writefln("freeBytes = %s", at.numBytesFree);
//     writefln("%s", at.allRegions.map!(it=>
//        "%s - %s %s".format(it[0],it[0]+it[1],it[2]?"F":"U")));
     //writefln("%s", at.getFreeRegionsByOffset);
     //writefln("%s", at.getFreeRegionsBySize);
//    assert(at.regionCache.length==at.allRegions.length);
//
//    float f = 0.4;
//    if(f<1) return;


    int findFree(int start) {
        int offset = 0;
        while(offset<data.length && data[offset]==1) offset++;
        return offset==data.length ? -1 : offset;
    }
    bool use(int size) {
        int offset = 0;
        while((offset = findFree(offset))!=-1) {
            if(data.length-offset<size) return false;
            int i = 0;
            for(; i<size; i++) if(data[offset+i]==1) break;
            if(i==size) {
                //writefln("use %s bytes at offset %s", size, offset);
                data[offset..offset+size] = 1;
                allocked ~= Regn(offset,size);
                return true;
            } else {
                offset++;
            }
        }
        return false;
    }
    void free(long offset, long size) {
        //writefln("free(%s,%s)",offset,size);
        data[offset..offset+size] = 0;
    }
    void check() {
        //writefln("Free regions should be:");
        int i = 0;
        int value = data[0];
        int offset = 0;
        int size = 0;
        int freeIndex = 0;
        auto freeRegions = at.getFreeRegionsByOffset();
        assert(at.getFreeRegionsBySize.length==freeRegions.length);
        long freeBytes = 0;

        while(i<data.length) {
            if(data[i]==0) freeBytes++;
            if(value!=data[i]) {
                // change
                if(value==0) {
                    // free region
                    //writefln("[%s] %s bytes",offset, size);
                    auto region = freeRegions[freeIndex];
                    if(region[0]!=offset || region[1]!=size) {
                        throw new Error("Ker-wrong @ %s (found %s,%s insead of %s,%s)".format(
                            freeIndex, region[0], region[1], offset, size));
                    }
                    freeIndex++;
                }
                offset = i;
                size = 0;
                value = data[i];
            }
            size++;
            i++;
        }
        if(value==0) {
            //writefln("[%s] %s bytes",offset, size);
            auto region = freeRegions[freeIndex];
            if(region[0]!=offset || region[1]!=size) {
                throw new Error("Ker-wrong @ %s (found %s,%s insead of %s,%s)".format(
                    freeIndex, region[0], region[1], offset, size));
            }
        }
        //writefln("free = %s, used = %s", freeBytes, data.length-freeBytes);
        if(at.numBytesFree!=freeBytes) throw new Error("freeBytes is wrong (%s. should be %s)".format(at.numBytesFree,freeBytes));

        ulong lastSize = 0;
        foreach(fr; at.getFreeRegionsBySize) {
            if(fr[1] < lastSize) {
                writefln("at=%s", at);
                throw new Error("wrong");
            }
            lastSize = fr[1];
        }

        //writefln("Check PASSED");
    }

    Mt19937 rng;
    for(auto j=0; j<100; j++) {
        auto seed = unpredictableSeed;
        //seed = 1172126497;
        rng.seed(seed);
        writefln("seed is %s", seed);

        data[] = 0;
        allocked.length = 0;
        at.freeAll();

        // allocate as much as possible
        while(true) {
            int size = uniform(1, 20, rng);
            if(!use(size)) break;
            if(at.alloc(size)==-1) throw new Error("Offset was -1");
        }
        //writefln("%s", at); flushConsole();
        //writefln("freeBytes=%s", at.numBytesFree);
        check();
        //writefln("freeing"); flushConsole();

        allocked.randomShuffle(rng);

        foreach(i, a; allocked) {
            if(false && i==4) {
                writefln("checking");
                check();
                writefln("%s", at);
                flushConsole();
                break;
            }
            //writefln("[%s] freeing %s %s", i, a.offset, a.size); flushConsole();
            free(a.offset,a.size);

            static if(__traits(compiles,at.free(f[0]))) {
                at.free(a.offset);
            } else {
                at.free(a.offset,a.size);
            }
            //writefln("%s", at); flushConsole();
            //check();
        }
        //writefln("%s", at); flushConsole();
        check();
        //writefln("%s", at);
    }

    {   // basic properties
        auto a = new Allocator(100);

        expect(a.numBytesFree==100);
        expect(a.numBytesUsed==0);
        expect(a.numFreeRegions==1);
        expect(a.freeRegions[0]==tuple(0,100));
    }

    {   // resize
        auto a = new Allocator(100);
        a.alloc(10);

        // expand where there is a free region at the end
        a.resize(200);

        expect(a.numBytesFree==190);
        expect(a.numBytesUsed==10);
        expect(a.numFreeRegions==1);
        expect(a.freeRegions[0]==tuple(10,190));

        a.freeAll();
        expect(a.numBytesFree==200);
        expect(a.numBytesUsed==0);
        expect(a.numFreeRegions==1);
        expect(a.freeRegions[0]==tuple(0,200));

        // expand where end of alloc memory is in use
        a.alloc(100);
        a.alloc(100);
        a.free(0, 100);
        expect(a.numBytesFree==100);
        expect(a.numBytesUsed==100);
        expect(a.numFreeRegions==1);
        expect(a.freeRegions[0]==tuple(0,100));

        a.resize(300);
        expect(a.numBytesFree==200);
        expect(a.numBytesUsed==100);
        expect(a.numFreeRegions==2);
        expect(a.freeRegions==[tuple(0,100), tuple(200,100)]);
        a.freeAll();

        // reduce where there is a free region at the end
        // | 50 used | 250 free | (size=300)
        a.alloc(50);
        expect(a.freeRegions==[tuple(50,250)]);
        expect(a.length==300);

        a.resize(250);
        // | 50 used | 200 free | (size=250)
        expect(a.length==250);
        expect(a.numBytesFree==200);
        expect(a.numBytesUsed==50);
        expect(a.numFreeRegions==1);
        expect(a.freeRegions==[tuple(50,200)]);

        // reduce so that the last free region is removed
        a.resize(50);
        // | 50 used | (size=50)
        expect(a.length==50);
        expect(a.numBytesFree==0);
        expect(a.numBytesUsed==50);
        expect(a.numFreeRegions==0);
        expect(a.freeRegions==[]);

        // attempt to reduce where end of alloc memory is in use
        a.resize(45);
        expect(a.length==50);

        writefln("%s", a);
    }

}
void testUtilities() {
    writefln("========--\nTesting utilities\n==--");

    // bitcast
    double d = 37.554;
    ulong l  = d.bitcast!ulong;
    double d2 = l.bitcast!double;
    writefln("d=%s, l=%s, d2=%s", d,l,d2);

    assert(bitcast!ulong(37.554).bitcast!double==37.554);

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

    writeln("testUtilities ran OK");
}
void testList() {
    writefln("--== Testing List ==--");

    auto a = new List!int;
    assert(a.empty && a.length==0);

    // add
    for(auto i=0; i<5; i++) a.add(i);
    assert(a.length==5 && !a.empty && a==[0,1,2,3,4]);
    a.add(5);
    assert(a.length==6 && a[5]==5);

    // remove
    assert(a.remove(0)==0 && a.length==5);
    assert(a==[1,2,3,4,5]);

    assert(a.remove(2)==3 && a.length==4);
    assert(a==[1,2,4,5]);

    assert(a.remove(3)==5 && a.length==3);
    assert(a==[1,2,4]);

    assert(a.remove(2)==4 && a.length==2);
    assert(a==[1,2]);

    assert(a.remove(1)==2 && a.length==1);
    assert(a==[1]);

    assert(a.remove(0)==1 && a.length==0);
    assert(a==[]);

    // insert
    a.clear();
    a.add(0).add(1).add(2);
    a.insert(99, 0);
    assert(a.length==4 && a==[99,0,1,2]);
    a.insert(55, 1);
    assert(a.length==5 && a==[99,55,0,1,2]);
    a.insert(33, 4);
    assert(a.length==6 && a==[99,55,0,1,33,2]);
    a.insert(11, 6);
    assert(a.length==7 && a==[99,55,0,1,33,2,11]);
}
void testArray() {
    writefln("==-- Testing Array --==");
    auto a = new Array!int;
    assert(a.empty && a.length==0);

    // add
    for(auto i=0; i<5; i++) a.add(i);
    assert(a.length==5 && !a.empty && a==[0,1,2,3,4]);
    a.add(5);
    assert(a.length==6 && a[5]==5);
    // removeAt
    assert(a.removeAt(0)==0 && a.length==5);
    assert(a==[1,2,3,4,5]);

    assert(a.removeAt(2)==3 && a.length==4);
    assert(a==[1,2,4,5]);

    assert(a.removeAt(3)==5 && a.length==3);
    assert(a==[1,2,4]);

    // removeAt array
    a.clear(); a.add([0,1,2,3,4]);
    a.removeAt(0, 2);
    assert(a==[2,3,4]);
    a.removeAt(1,2);
    assert(a==[2]);
    a.removeAt(0,1);
    assert(a==[]);
    a.add([0,1,2,3,4]);
    a.removeAt(0,5);
    assert(a==[]);
    a.add([1,2,3]);
    a.removeAt(0,0);
    assert(a==[1,2,3]);
    a.removeAt(1, 1000);
    assert(a==[1] && a.length==1);

    {   // remove
        a.clear(); a.add([0,1,2,3,4]);
        assert(a.remove(2)==2 && a.length==4 && a==[0,1,3,4]);
        assert(a.remove(7)==0 && a.length==4 && a==[0,1,3,4]);
        assert(a.remove(0)==0 && a.length==3 && a==[1,3,4]);
        assert(a.remove(4)==4 && a.length==2 && a==[1,3]);
    }

    // add array
    a.clear(); a.add([1,2,4]);
    a.add([10,11,12]);
    assert(a.length==6 && a==[1,2,4,10,11,12]);

    a.add([13,14,15,16]);
    assert(a.length==10 && a==[1,2,4,10,11,12,13,14,15,16]);

    // insertAt
    a.clear();
    a.add(0).add(1).add(2);
    a.insertAt(0, 99);
    assert(a.length==4 && a==[99,0,1,2]);
    a.insertAt(1, 55);
    assert(a.length==5 && a==[99,55,0,1,2]);
    a.insertAt(4, 33);
    assert(a.length==6 && a==[99,55,0,1,33,2]);
    a.insertAt(6, 11);
    assert(a.length==7 && a==[99,55,0,1,33,2,11]);

    // insertAt array
    a.clear(); a.add([0,1,2,3,4]);
    a.insertAt(0, [8,9]);
    assert(a==[8,9,0,1,2,3,4] && a.length==7);
    a.insertAt(0, []);
    assert(a==[8,9,0,1,2,3,4] && a.length==7);
    a.insertAt(2, [90]);
    assert(a==[8,9,90,0,1,2,3,4] && a.length==8);
    a.insertAt(7, [100]);
    assert(a==[8,9,90,0,1,2,3,100,4] && a.length==9);
    a.insertAt(9, [200]);
    assert(a==[8,9,90,0,1,2,3,100,4,200] && a.length==10);

    // opIndex(), opSlice and opDollar
    a.clear();
    a.add([1,2,3]);
    assert(a[]==[1,2,3]);
    assert(a[0..2]==[1,2] && a[0..1]==[1]);
    assert(a[0..$]==[1,2,3]);

    // move (forwards)
    a.clear();
    a.add([0,1,2,3,4]);
    a.move(2,0);
    assert(a==[2,0,1,3,4]);
    a.move(4,3);
    assert(a==[2,0,1,4,3]);
    a.move(4,4);
    assert(a==[2,0,1,4,3]);
    a.move(4,0);
    assert(a==[3,2,0,1,4]);
    // move (backwards)
    a.clear();
    a.add([0,1,2,3,4]);
    a.move(1,3);
    assert(a==[0,2,3,1,4]);
    a.move(0,4);
    assert(a==[2,3,1,4,0]);

    { // opCatAssign
        auto array = new Array!char;
        array ~= 'a';
        assert(array.length==1 && array[0]=='a');
        array ~= ['b','c'];
        assert(array.length==3 && array==['a','b','c']);
    }

    {// opApply
        auto array = new Array!int;
        array.add([1,5,7]);
        int total = 0;
        foreach(v; array) {
            total += v;
        }
        assert(total==13);

        total = 0;
        foreach(i, v; array) {
            total += i;
            total += v;
        }
        assert(total==13+3);
    }
}
void testStructCache() {
    writefln("--== Testing StructCache ==--");

    align(1) struct A {int[3] a; ubyte b;} // 13 bytes
    struct B {ubyte a;}

    auto cache = new StructCache!A(4, 1);

    A* a1 = cache.take();
    writefln("a1=%s", cast(ulong)a1);
    assert(a1 && cache.length==1);
    cache.release(a1);
    assert(cache.length==0);

    A* a2 = cache.take();
    writefln("a2=%s", cast(ulong)a2);
    cache.release(a2);

    writefln("---");

    A* a3 = cache.take();
    A* a4 = cache.take();
    A* a5 = cache.take();
    A* a6 = cache.take();
    writefln("%s %s %s %s",
        cast(ulong)a3,
        cast(ulong)a4,
        cast(ulong)a5,
        cast(ulong)a6
    );


    A* a7 = cache.take();
    writefln("a7=%s", cast(ulong)a7);
    assert(cache.length==5);

    cache.release(a6);
    assert(cache.length==4);

    cache.release(a7);
    assert(cache.length==3);

    A* a8 = cache.take();
    A* a9 = cache.take();
    A* a10 = cache.take();
    A* a11 = cache.take();
    A* a12 = cache.take();
    A* a13 = cache.take();
    A* a14 = cache.take();
    A* a15 = cache.take();
    A* a16 = cache.take();

    A* a17 = cache.take();

    cache.release(a17);

    cache.release(a8);
    cache.release(a4);
    cache.release(a3);
    cache.release(a5);
    writefln("%s", cache);

    cache.take();
    writefln("%s", cache);

}
void testObjectCache() {
    writefln("--== Testing ObjectCache ==--");

    static class Thingy { this(int a) {} }
    auto cache = new ObjectCache!Thingy;

    cache.release(new Thingy(1));
    cache.release(new Thingy(2));
    assert(cache.numAvailable==2);

    auto t1 = cache.take();
    auto t2 = cache.take();
    cache.release(t1);
    cache.release(t2);
    assert(cache.numAvailable==2);

    auto t3 = cache.take();
    assert(cache.numAvailable==1);
}
void testBool3() {
    writefln("--== Testing Bool3 ==--");
    bool3 b0;
    bool3 b1 = true;
    bool3 b2 = false;
    bool3 b3 = bool3.unknown;
    assert(b0.isUnknown);
    assert(b1);
    assert(!b2);
    assert(b3.isUnknown);
}
void testTreeList() {
    writefln("--== Testing TreeList ==--");

    static class A {
        int a;
        this(int a) { this.a = a; }
        alias opCmp = Object.opCmp;
        int opCmp(A o) { return o.a==a ? 0 : o.a<a ? 1 : -1; }
        override bool opEquals(Object o) {
            return a==(cast(A)o).a;
        }
        override string toString() { return "%s".format(a); }
    }
    auto tree = new TreeList!A;
    //writefln("tree=%s", tree);

    assert(tree.empty && tree.length==0);

    tree.add(new A(10));
    assert(!tree.empty && tree.length==1 && tree==[new A(10)]);

    tree.add(new A(30));
    assert(tree.remove(new A(30)));
    assert(false==tree.remove(new A(30)));

    auto tree2 = new TreeList!int;
    tree2.add(20);
    tree2.add(5);
    tree2.add(7);
    tree2.add(15);
    tree2.add(17);
    tree2.add(30);
    tree2.add(2);
    assert(tree2.length==7);
    assert(tree2==[2,5,7,15,17,20,30]);

    auto tree3 = new TreeList!int;
    tree3.add(20);
    tree3.add(5);
    tree3.add(7);
    tree3.add(15);
    tree3.add(17);
    tree3.add(30);
    tree3.add(2);
    assert(tree3.length==7);
    assert(tree3==[2,5,7,15,17,20,30]);
    writefln("%s", tree2);
    writefln("%s", tree3);
    assert(tree3==tree2);


    writefln("tree=%s", tree2);
}
void testQueue() {
    writefln("--== Testing Queue ==--");

    auto q = new Queue!int(1024);
    assert(q.length==0 && q.empty);

    q.push(1);
    assert(q.length==1 && !q.empty);

    q.push(2).push(3);
    assert(q.length==3);

    assert(q.pop()==1 && q.length==2);
    assert(q.pop()==2 && q.length==1);
    assert(q.pop()==3 && q.length==0 && q.empty);

    q.push(30);
    q.clear();
    assert(q.length==0 && q.empty);

    // drain
    int[] temp = new int[4];
    q.clear();
    q.push(1).push(3).push(7);
    assert(q.drain(temp)==3 && temp[0..3]==[1,3,7]);

    q.push(1).push(3).push(7).push(11).push(13);
    assert(q.drain(temp)==4 && temp[0..4]==[1,3,7,11]);

    assert(q.drain(temp)==1 && temp[0]==13);

    assert(q.drain(temp)==0);

    /// valuesDup
    {
        auto queue = new Queue!int(1024);
        queue.push(1).push(2).push(3);
        assert(queue.valuesDup() == [1,2,3]);
        queue.pop();
        assert(queue.valuesDup() == [2,3]);
    }
    /// pushToFront
    {
        auto queue = new Queue!int(1024);
        queue.push(1).push(2).push(3);
        queue.pushToFront(4);
        assert(queue.valuesDup() == [4,1,2,3]);
        queue.pop();
        assert(queue.valuesDup() == [1,2,3]);
    }
}
void testPDH() {
    writefln("--== Testing CPUUsage ==--");

    auto pdh = new PDH();
    scope(exit) pdh.destroy();

    pdh.dumpPaths("\\Process(*)\\*"w);

    for(auto i=0; i<2; i++) {
        Thread.sleep(dur!"msecs"(500));
        double total = pdh.getCPUTotalPercentage();
        double[] cores = pdh.getCPUPercentagesByCore();

        writefln("{");
        writefln("  Total : %5.2f %s", total, "*".repeat(cast(int)(total/5)));
        foreach(n, d; cores) {
            writefln("  Core %s : %5.2f %s", n, d, "*".repeat(cast(int)(d/5)));
        }
        writefln("}");
        flushConsole();
    }
}
void testSet() {
    writefln("--== Testing Set ==--");

    {
        auto s = new Set!int;
        assert(s.empty && s.length==0);

        s.add(2).add(4);
        assert(!s.empty && s.length==2);
        assert(s.contains(2) && s.contains(4));

        s.add(2).add(3);
        assert(!s.empty && s.length==3);
        assert(s.contains(2) && s.contains(3) && s.contains(4));

        assert(s.remove(2)==true);
        assert(s.length==2);

        assert(s.remove(1)==false);
        assert(s.length==2);

        assert(s.values==[3,4] || s.values==[4,3]);
    }

    { // ==
        auto s1 = new Set!int;
        auto s2 = new Set!int;
        auto s3 = new Set!float;

        assert(s1==s2);
        assert(s1!=s3);

        s1.add([1,20,30,40,500]);
        s2.add([500,40,30,20,1]);
        writefln("s1 = %s", s1.values);
        writefln("s2 = %s", s2.values);
        assert(s1==s2);
        s1.add(2);
        assert(s1!=s2);
        s2.add(2);
        assert(s1==s2);
    }
}
void testStack() {
    writefln("--== Testing Stack ==--");
    auto stack = new Stack!uint(10);
    assert(stack==[] && stack.length==0 && stack.empty);
    writefln("%s", stack);

    stack.push(13);
    assert(stack==[13] && stack.length==1 && !stack.empty);
    writefln("%s", stack);

    stack.push(17);
    assert(stack==[13,17] && stack.length==2 && !stack.empty);
    assert(stack[]==[13,17]);
    writefln("%s", stack);

    assert(stack.pop()==17);
    assert(stack==[13] && stack.length==1 && !stack.empty);
    writefln("%s", stack);

    assert(stack.pop()==13 && stack.length==0 && stack.empty);
    assert(stack[]==[]);

    { // peek
        auto s = new Stack!int;
        assert(s.peek()==0);
        assert(s.peek(-1)==0);
        assert(s.peek(1)==0);

        s.push(1);
        assert(s.peek()==1);
        assert(s.peek(0)==1);

        s.push(2);
        assert(s.peek()==2);
        assert(s.peek(0)==2);
        assert(s.peek(1)==1);

        s.push(3);
        assert(s.peek()==3);
        assert(s.peek(0)==3);
        assert(s.peek(1)==2);
        assert(s.peek(2)==1);

        s.pop();
        assert(s.peek()==2);
        s.pop();
        assert(s.peek()==1);
        s.pop();
        assert(s.peek()==0);
    }
}
void testByteReader() {
    writefln("--== Testing ByteReader ==--");

    {
        writefln("FileByteReader...");
        string dir = tempDir();
        string filename = dir~uniform(0,100).to!string~"file.bin";
        scope f = File(filename, "wb");
        scope(exit) { remove(filename); }
        ubyte[256] data;

        void writeTestData() {
            for(auto i=0; i<data.length; i++) {
                data[i] = cast(ubyte)uniform(0,255);
            }
            f.rawWrite(data);
        }
        writeTestData();
        f.close();

        // read
        FileByteReader r = new FileByteReader(filename, 8);
        scope(exit) r.close();

        assert(r.length==256);
        assert(r.position==0);

        auto b1 = r.read!ubyte;
        assert(b1==data[0]);
        assert(r.position==1);

        auto s1 = r.read!ushort();
        assert(s1==(data[1] | data[2]<<8));
        assert(r.position==3);

        auto i1 = r.read!uint();
        assert(i1==(data[3] | (data[4]<<8) | (data[5]<<16) | (data[6]<<24)));
        assert(r.position==7);

        auto l1 = r.read!ulong();
        assert(l1==(
            cast(ulong)data[7] | (cast(ulong)data[8]<<8) | (cast(ulong)data[9]<<16) | (cast(ulong)data[10]<<24) |
            (cast(ulong)data[11]<<32) | (cast(ulong)data[12]<<40) | (cast(ulong)data[13]<<48) | (cast(ulong)data[14]<<56)
        ));
        assert(r.position==15);

        auto b2 = r.read!ubyte();
        assert(b2==data[15]);
        assert(r.position==16);

        auto s2 = r.read!ushort;
        assert(s2==(data[16] | (data[17]<<8)));
        assert(r.position==18);

        auto s3 = r.read!ushort;
        assert(s3==(data[18] | (data[19]<<8)));
        assert(r.position==20);

        auto i2 = r.read!uint;
        assert(i2==(data[20] | (data[21]<<8) | (data[22]<<16) | (data[23]<<24)));
        assert(r.position==24);

        // readArray
        auto a1 = r.readArray!ubyte(2);
        assert(a1==data[24..24+2]);
        assert(r.position==26);

        auto a2 = r.readArray!ubyte(5);
        assert(a2==data[26..26+5]);
        assert(r.position==31);

        auto a3 = r.readArray!ubyte(12);
        assert(a3==data[31..31+12]);
        assert(r.position==43);

        // skip
        auto b3 = r.read!ubyte;
        assert(b3==data[43]);
        assert(r.position==44);

        r.skip(2);
        assert(r.position==46);

        r.skip(9);
        assert(r.position==55);
        r.close();
    }

    {
        writefln("ByteReader...");
        ubyte[] b = [cast(ubyte)1,2,3,4,5,6,7,8,9,0];
        auto reader = new ByteReader(b);
        assert(reader.length==b.length);

        ubyte[] buf;

        while(!reader.eof) {
            buf ~= reader.read!ubyte;
        }
        assert(buf.length==b.length);
        assert(buf[] == b[]);


        reader.rewind();
        assert(reader.position==0);
        assert(reader.read!ushort==(0x0201).as!ushort && reader.position==2);
        assert(reader.read!uint==(0x06050403).as!uint && reader.position==6);
        reader.skip(1);
        assert(reader.position==7);
        assert(reader.read!ubyte==(0x08).as!ubyte && reader.position==8);
        assert(reader.read!uint==(0x00000009).as!uint && reader.position==10 && reader.eof);

        assert(reader.read!ubyte==0); 

        reader.rewind();
        assert(reader.position==0);

        assert(reader.readArray!ubyte(3) == cast(ubyte[])[1,2,3] && reader.position==3);
        assert(reader.readArray!ushort(2) == cast(ushort[])[0x0504, 0x0706] && reader.position==7);
        assert(reader.readArray!ubyte(8) == cast(ubyte[])[8,9,0,0,0,0,0,0] && reader.eof);

        reader.rewind();

        assert(reader.readArray!uint(5) == [0x04030201, 0x08070605, 0x00000009, 0,0]);

        reader.close();
        assert(reader.eof);
    }
}
void testByteWriter() {
    writefln("Testing ByteWriter...");

    string dir = tempDir();
    string filename = dir~uniform(0,100).to!string~"file.bin";
    scope(exit) { if(exists(filename)) remove(filename); }

    {
        auto w = new FileByteWriter(filename);

        w.write!ubyte(0xfe);
        assert(w.getBytesWritten==1);
        w.write!byte(-1);
        assert(w.getBytesWritten==2);
        w.write!ushort(0xee11);
        assert(w.getBytesWritten==4);
        w.write!uint(0xff);
        assert(w.getBytesWritten==8);
        w.write!ulong(0);
        assert(w.getBytesWritten==16);

        auto bw = w.getBitWriter();
        bw.write(0b101, 3);
        bw.flush();         // push the current byte out to the ByteWriter

        w.close();
    }
    auto r = new FileByteReader(filename); 

    assert(r.read!ubyte==0xfe);
    assert(r.read!byte==-1);
    assert(r.read!ushort==0xee11);
    assert(r.read!uint==0xff);
    assert(r.read!ulong==0);

    assert(r.read!ubyte==0b101);
    r.close();
}
void testArrayByteWriter() {
    writefln("Testing ArrayByteWriter...");

    {
        auto w = new ArrayByteWriter;

        w.write!ubyte(0x89);
        assert(w.length==1 && w.getArray==[0x89]);

        w.write!ushort(0xd1d2);
        assert(w.length==3 && w.getArray==[0x89, 0xd2, 0xd1]);

        w.write!uint(0x01020304);
        assert(w.length==7 && w.getArray==[0x89, 0xd2, 0xd1, 4,3,2,1]);

        w.write!ulong(0x0102030405060708L);
        assert(w.length==15 && w.getArray==[0x89, 0xd2, 0xd1, 4,3,2,1, 8,7,6,5,4,3,2,1]);

        w.writeArray!ubyte(cast(ubyte[])[6,7,8]);
        assert(w.length==18 && w.getArray==[0x89, 0xd2, 0xd1, 4,3,2,1, 8,7,6,5,4,3,2,1, 6,7,8]);

        w.reset();
        assert(w.length==0);

        w.writeArray!ushort(cast(ushort[])[0x0304, 0x0506]);
        assert(w.length==4 && w.getArray==[4,3,6,5]);

        w.writeArray!uint([1,2]);
        assert(w.length==12 && w.getArray==[4,3,6,5, 1,0,0,0, 2,0,0,0]);

        w.pack();
        assert(w.length==12 && w.getReservedLength==12);

        w.writeArray!ulong([1]);
        assert(w.length==20 && w.getArray==[4,3,6,5, 1,0,0,0, 2,0,0,0, 1,0,0,0,0,0,0,0]);
    }
}
void testBitWriter() {
    writefln("--== Testing BitWriter ==--");

    ubyte[] received;

    void receiver(ubyte b) {
        writefln("%08b %02x", b, b);
        received ~= b;
    }

    auto writer = new BitWriter(&receiver);

    writer.write(0b11111111, 8);
    assert(received==[0xff]);
    assert(writer.bitsWritten==8);
    assert(writer.bytesWritten==1);

    writer.write(0b00001111, 4);
    assert(received==[0xff]);
    assert(writer.bitsWritten==12);
    assert(writer.bytesWritten==1);

    writer.write(0b00001111, 4);
    assert(received==[0xff, 0xff]);
    assert(writer.bitsWritten==16);
    assert(writer.bytesWritten==2);

    received.length = 0;
    writer.write(0b00001001, 4);
    assert(received==[]);
    assert(writer.bitsWritten==20);
    assert(writer.bytesWritten==2);

    writer.write(0b00001111, 4);
    assert(received==[0b11111001]);
    assert(writer.bitsWritten==24);
    assert(writer.bytesWritten==3);

    received.length = 0;
    writer.write(0b11111111, 7);
    assert(received==[]);
    assert(writer.bitsWritten==31);
    assert(writer.bytesWritten==3);

    writer.write(0b11111111, 1);
    assert(received==[0xff]);
    assert(writer.bitsWritten==32);
    assert(writer.bytesWritten==4);

    received.length = 0;
    writer.write(0b01, 2);
    writer.write(0b10, 2);
    writer.write(0b11, 2);
    writer.write(0b00, 2);
    assert(received==[0b00111001]);
    assert(writer.bitsWritten==40);
    assert(writer.bytesWritten==5);

    received.length = 0;
    writer.write(0xffffffff, 5);
    assert(writer.bitsWritten==45);
    assert(writer.bytesWritten==5);

    writer.flush();                 // 3 extra bits written
    assert(received==[0b11111]);
    assert(writer.bitsWritten==48);
    assert(writer.bytesWritten==6);

    received.length = 0;
    writer.write(0xffffffff, 3);
    writer.write(0, 2);
    writer.write(0xffffffff, 2);
    assert(writer.bitsWritten==55);
    assert(writer.bytesWritten==6);

    writer.flush();                 // 1 extra bit written
    assert(received==[0b1100111]);
    assert(writer.bitsWritten==56);
    assert(writer.bytesWritten==7);

    received.length = 0;
    writer.write(0xffffffff, 9);
    writer.write(0x01, 2);
    assert(writer.bitsWritten==67);
    assert(writer.bytesWritten==8);

    writer.flush();                 // 5 extra bits written
    assert(received==[0xff, 0b011]);
    assert(writer.bitsWritten==72);
    assert(writer.bytesWritten==9);

    writer.flush();                 // no change
    assert(writer.bitsWritten==72);
    assert(writer.bytesWritten==9);

    writer.write(0, 1);
    writer.flush();                 // flush 7 bits
    assert(writer.bitsWritten==80);
    assert(writer.bytesWritten==10);
}
void testBitReader() {
    writefln("--== Testing BitReader==--");

    ubyte[] bytes = [
        0b11111111, // [0]
        0b11110000, // [1]
        0b00001111, // [2]
        0b00110011, // [3]
        0b01010101, // [4]
        0b00100101, // [5]
        0b11111111, // [6]
        0b11111111, // [7]
        0b00110011  // [8]
    ];
    uint ptr;

    void reset() { ptr = 0; }
    ubyte byteProvider() {
        writefln("%08b %02x", bytes[ptr], bytes[ptr]);
        return bytes[ptr++];
    }

    {   // read 
        auto r = new BitReader(&byteProvider);

        assert(0b11111111==r.read(8));
        assert(0b11110000==r.read(8));
        assert(0b00001111==r.read(8));
        assert(r.isAtStartOfByte);

        assert(0b0011==r.read(4) && !r.isAtStartOfByte);
        assert(0b0011==r.read(4) && r.isAtStartOfByte);

        assert(0b01==r.read(2) && !r.isAtStartOfByte);
        assert(0b01==r.read(2) && !r.isAtStartOfByte);
        assert(0b01==r.read(2) && !r.isAtStartOfByte);
        assert(0b01==r.read(2) && r.isAtStartOfByte);

        assert(0b1==r.read(1));
        assert(0b10==r.read(2));
        assert(0b100==r.read(3));
        assert(0b00==r.read(2) && r.isAtStartOfByte);
    }

    {   // skipToEndOfByte
        reset();
        auto r = new BitReader(&byteProvider);
        
        // bytes[0] = 0b11111111
        assert(1 == r.read(1));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[1] = 0b11110000
        assert(0==r.read(2));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[2] = 0b00001111
        assert(7==r.read(3));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[3] = 0b00110011
        assert(3==r.read(4));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[4] = 0b01010101
        assert(21==r.read(5));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[5] = 0b00100101
        assert(37==r.read(6));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[6] = 0b11111111
        assert(127==r.read(7));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[7] = 0b11111111
        assert(255==r.read(8));
        r.skipToEndOfByte();        // nothing skipped
        assert(r.isAtStartOfByte);

        // bytes[8] = 0b00110011
        assert(0b00110011==r.read(8) && r.isAtStartOfByte);
    }

    {
        writefln("FileBitReader");

        // create a temp file and write some bits to it
        string dir = tempDir();
        string filename = dir~uniform(0,100).to!string~"file.bin";
        scope f = File(filename, "wb");
        scope(exit) { f.close(); remove(filename); }

        auto writer = new FileBitWriter(filename);
        writer.write(0b1000, 4);
        writer.write(0b0101, 4);
        writer.write(0b11111, 5);
        writer.write(0b00111, 5);
        writer.write(0b11, 2);
        writer.write(0b010, 3);

        writer.close();

        // test the FileBitReader
        auto reader = new FileBitReader(filename);
        assert(reader.read(4)==0b1000);
        assert(reader.read(4)==0b0101);
        assert(reader.read(5)==0b11111);
        assert(reader.read(5)==0b00111);
        assert(reader.read(2)==0b11);
        assert(reader.read(3)==0b010);
        reader.close();
    }
}
void testBitReaderAndWriter() {
    writefln("--== Testing BitReader ==--");

    Mt19937 rng;
    rng.seed(unpredictableSeed);
    //rng.seed(1);
    uint[] bitValues;
    uint[] bitLengths;
    uint length = 1000;
    for(auto i=0; i<length; i++) {
        uint bl = uniform(0, 8, rng);
        uint bv = uniform(0, 1<<bl, rng);
        bitValues  ~= bv;
        bitLengths ~= bl;
    }
    writefln("bitValues  = %s", bitValues.map!(it=>"%2u".format(it)).join(", "));
    writefln("bitLengths = %s", bitLengths.map!(it=>"%2u".format(it)).join(", "));

    uint ptr;
    ubyte[] bytesWritten;
    ubyte getNextByte() {
        return bytesWritten[ptr++];
    }
    void byteWritten(ubyte b) {
        bytesWritten ~= b;
    }

    auto r = new BitReader(&getNextByte);
    auto w = new BitWriter(&byteWritten);

    for(auto i=0; i<length; i++) {
        w.write(bitValues[i], bitLengths[i]);
    }
    w.flush();

    writefln("bytesWritten = %s", bytesWritten);

    uint[] valuesRead;
    for(auto i=0; i<length; i++) {
        valuesRead ~= r.read(bitLengths[i]);
    }
    writefln("values     = %s", valuesRead.map!(it=>"%2u".format(it)).join(", "));

    assert(valuesRead==bitValues);
}
void testArrayUtils() {
    writefln("--== Testing array_utils ==--");

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
void testVelocity() {
    writefln("--== Testing velocity ==--");

    string templ1 =
        "<html>" ~
        "$LOOP $ITEMS $it" ~
        "$IF $bool " ~
        "<p>$key1 $it.a $it.b</p>" ~
        "$END" ~
        "$END" ~
        "</html>" ~
        "";

    auto v = Velocity.fromString(templ1);
    v.set("bool", "true");
    v.set("key1", "hello");
    v.set("ITEMS", [    // 2 iterations
        ["a":"1"],
        ["a":"2"]
    ]);
    auto output1 = v.process();

    v.set("bool", cast(string)null);
    auto output2 = v.process();

    writefln("output1=\n%s", output1);
    writefln("output2=\n%s", output2);

    assert(output1=="<html> <p>hello 1 </p> <p>hello 2 </p></html>");
    assert(output2=="<html></html>");

}
void testStringBuffer() {
    writefln("--== Testing StringBuffer ==--");
    { // add, ~=, length and empty
        auto buf = new StringBuffer;
        assert(buf.length==0 && buf.empty);
        buf.add('a')
           .add("bc");
        buf ~= 'd';
        buf ~= "ef";
        assert(buf=="abcdef" && buf.length==6 && !buf.empty);
    }
    { // add(format)
        auto buf = new StringBuffer;
        buf.add("%s %s", 10, true);
        writefln("%s", buf.toString());
        assert(buf=="10 true");
    }
    { // equality
        auto buf  = new StringBuffer("abcd");
        auto buf2 = new StringBuffer("abcd");
        auto buf3 = new StringBuffer("abc");
        assert(buf=="abcd");
        assert(buf!="bbcd");
        assert(buf!="abc");
        assert(buf==buf2);
        assert(buf!=buf3);
    }
    { // indexing and slicing
        auto buf = new StringBuffer("abcd");
        auto a = buf[];
        auto b = buf[0];
        auto c = buf[0..$];
        auto d = buf[1..3];
        assert(a=="abcd");
        assert(b=='a');
        assert(c=="abcd");
        assert(d=="bc");
    }
    {   // clear
        auto buf = new StringBuffer("abcd");
        assert(buf.clear()=="");
    }
    { // indexOf and contains
        auto buf = new StringBuffer("abcdef");
        assert(buf.indexOf('a')==0);
        assert(buf.indexOf('z')==-1);
        assert(buf.indexOf('f')==5);
        assert(buf.indexOf("a")==0);
        assert(buf.indexOf("ac")==-1);
        assert(buf.indexOf("cde")==2);

        assert(buf.contains('d'));
        assert(!buf.contains('D'));
        assert(buf.contains("de"));
        assert(!buf.contains("df"));
    }
    {   // insert
        auto buf = new StringBuffer("abcdef");
        buf.insert('.', 0);
        assert(buf==".abcdef");
        buf.insert('.', 7);
        assert(buf==".abcdef.");
    }
    {   // remove
        auto buf = new StringBuffer("abcdef");
        buf.remove(0);
        assert(buf=="bcdef");
        buf.remove(4);
        assert(buf=="bcde");
    }
}
void testHasher() {
    writefln("--== Testing Hasher ==--");
    {
        auto m1 = Hasher.murmur("abcdefgh");
        auto m2 = Hasher.murmur("abcdefgh");
        writefln("murmurhash = %s", m1);
        assert(m1==m2);

        auto s1 = Hasher.sha1("abcdefgh");
        auto s2 = Hasher.sha1("abcdefgh");
        auto s3 = Hasher.sha1("");
        writefln("sha1       = %s", s1);
        writefln("sha1       = %s", s3);
        assert(s1==s2);
        assert(s1!=s3);

        /// isValid
        assert(m1.isValid && m2.isValid && s1.isValid && s2.isValid && s3.isValid);

        m1.invalidate();
        assert(!m1.isValid);

        Hash!20 h;
        assert(!h.isValid);
    }
}
void testPriorityQueue() {
    writefln("Testing PriorityQueue...");

    {
        auto q = makeHighPriorityQueue!int;
        assert(q.empty && q.length==0);

        q.push(5);
        assert(!q.empty && q.length==1 && q.asArray == [5]);

        assert(q.push(3).length==2 && q.asArray == [3, 5]);
        assert(q.push(7).length==3 && q.asArray == [3, 5, 7]);
        assert(q.push(1).asArray == [1, 3, 5, 7]);
        assert(q.push(10).asArray == [1, 3, 5, 7, 10]);
        assert(q.push(10).asArray == [1, 3, 5, 7, 10, 10]);
        assert(q.push(9).asArray == [1, 3, 5, 7, 9, 10, 10]);

        assert(q.pop() == 10 && q.length==6 && q.asArray==[1, 3, 5, 7, 9, 10]);
        assert(q.pop() == 10 && q.length==5 && q.asArray==[1, 3, 5, 7, 9]);
        assert(q.pop() == 9 && q.length==4 && q.asArray==[1, 3, 5, 7]);
        assert(q.pop() == 7 && q.length==3 && q.asArray==[1, 3, 5]);
        assert(q.pop() == 5 && q.length==2 && q.asArray==[1, 3]);
        assert(q.pop() == 3 && q.length==1 && q.asArray==[1]);
        assert(q.pop() == 1 && q.length==0 && q.empty && q.asArray==[]);

        assert(q.push(10).length==1 && q.asArray==[10]);
        assert(q.push(0).length==2 && q.asArray==[0, 10]);

        assert(q.clear().length == 0 && q.empty && q.asArray==[]);
    }
    {   // High priority queue with struct values
        struct S {
            int value;

            int opCmp(inout S other) const {
                return value==other.value ? 0 : value < other.value ? -1 : 1;
            }
            bool opEquals(inout S other) const  {
                return value == other.value;
            }
        }
        auto q = makeHighPriorityQueue!S;

        assert(q.push(S(1)).length==1 && q.asArray==[ S(1) ]);
        assert(q.push(S(3)).length==2 && q.asArray==[ S(1), S(3) ]);
        assert(q.push(S(2)).length==3 && q.asArray==[ S(1), S(2), S(3) ]);
        assert(q.pop() == S(3) && q.length == 2 && q.asArray == [S(1), S(2)]);
    }
    {   // Low priority queue
        auto q = makeLowPriorityQueue!int;
        assert(q.empty && q.length==0);

        q.push(5);
        assert(!q.empty && q.length==1 && q.asArray == [5]);

        assert(q.push(3).length==2 && q.asArray == [5, 3]);
        assert(q.push(7).length==3 && q.asArray == [7, 5, 3]);
        assert(q.push(1).asArray == [7,5,3,1]);
        assert(q.push(10).asArray == [10,7,5,3,1]);
        assert(q.push(10).asArray == [10,10,7,5,3,1]);
        assert(q.push(9).asArray == [10,10,9,7,5,3,1]);

        assert(q.pop() == 1 && q.length==6 && q.asArray==[10,10,9,7,5,3]);
        assert(q.pop() == 3 && q.length==5 && q.asArray==[10,10,9,7,5]);
        assert(q.pop() == 5 && q.length==4 && q.asArray==[10,10,9,7]);
        assert(q.pop() == 7 && q.length==3 && q.asArray==[10,10,9]);
        assert(q.pop() == 9 && q.length==2 && q.asArray==[10,10]);
        assert(q.pop() == 10 && q.length==1 && q.asArray==[10]);
        assert(q.pop() == 10 && q.length==0 && q.empty && q.asArray==[]);
    }
}
void testConsole() {
    writefln("Testing console...");

    /// Note: This needs to be run from an actual console not the IDE.

    scope(exit) Console.reset();

    Console.set(Console.Attrib.RED);
    writefln("red");

    Console.set(Console.Attrib.GREEN);
    writefln("green");
    Console.set(Console.Attrib.BLUE);
    writefln("blue");
    Console.set(Console.Attrib.YELLOW);
    writefln("yellow");
    Console.set(Console.Attrib.MAGENTA);
    writefln("magenta");
    Console.set(Console.Attrib.CYAN);
    writefln("cyan");
    Console.set(Console.Attrib.WHITE | Console.Attrib.UNDERSCORE);
    writefln("white");

    Console.set(Console.Attrib.BG_RED);
    writefln("red background");
    Console.set(Console.Attrib.BG_GREEN);
    writefln("green background");
    Console.set(Console.Attrib.BG_BLUE);
    writefln("blue background");
    Console.set(Console.Attrib.BG_YELLOW);
    writefln("yellow background");
    Console.set(Console.Attrib.BG_MAGENTA);
    writefln("magenta background");
    Console.set(Console.Attrib.BG_CYAN);
    writefln("cyan background");
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

    AssertSingleThreaded ast;

    /// This should be ok
    ast.check();
    /// And again
    ast.check();
    writefln("\tOK");
    t.join();


    auto t2 = new Thread( () {
        writefln("\tT2 thread ID   = %s", Thread.getThis.id);

        /// This is bad
        //ast.check();

    } );
    t2.start();

    t2.join();
}