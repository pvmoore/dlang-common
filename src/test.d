
import std.stdio;
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

import common;

import _tests.test_async;
import _tests.test_betterc;
import _tests.test_containers;
import _tests.test_io;
import _tests.test_parser;
import _tests.test_utils;
import _tests.test_wasm;

enum RUN_SUBSET = true;

extern(C) void asm_test();

void main() {
    runTests();
    static if(!RUN_SUBSET) {

    }
    version(assert) {

    } else {
        writefln("WARNING!! running test in release mode - asserts are disabled");
    }

}
void runTests() {
    writefln("Running tests");
    scope(failure) writefln("-- FAIL");
    scope(success) writeln("-- OK - All standard tests finished\n");

    static if(RUN_SUBSET) {
        //testAsmUtils();
        //asm_test();
        //testParser();
        testPDH();
    } else {

        testAllocator();
        testBool3();
        testHasher();
        testObjectCache();
        testPDH();
        testStringBuffer();
        testStructCache();
        testVelocity();

        testBetterc();
        testContainers();
        testIo();
        testUtils();
        testWasm();

        runAsyncTests();
    }
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
void testPDH() {
    writefln("--== Testing CPUUsage ==--");

version(Win64) {
    auto pdh = new PDH(1000);
    pdh.start();
    scope(exit) pdh.destroy();

    auto status = pdh.validatePath("\\Processor(%s)\\%% Processor Time"w.format(0));
    assert(status == 0);

    //pdh.dumpPaths("\\Process(*)\\*"w);
    auto paths = pdh.getPaths("\\Processor(*)\\*"w);
    //pdh.dumpCounters();
    foreach(p; paths) {
        writefln("%s", p);
    }

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
