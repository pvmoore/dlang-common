module _tests.test;

import std.stdio;
import core.stdc.stdlib : malloc, calloc;
import core.atomic      : atomicLoad, atomicStore, atomicOp;
import core.time        : dur;
import core.thread      : Thread, thread_joinAll;
import core.memory      : GC;

import std.random              : randomShuffle,uniform, Mt19937, unpredictableSeed;
import std.format              : format;
import std.conv                : to;
import std.typecons            : Tuple,tuple;
import std.range               : array,stride,join,iota;
import std.parallelism         : parallel, task;
import std.file                : exists, tempDir, remove;
import std.array               : join;
import std.datetime.stopwatch  : benchmark, StopWatch;
import std.algorithm.iteration : permutations, map, sum, each;
import std.algorithm.sorting   : sort;
import std.algorithm.mutation  : reverse;

import common;

import _tests.test_allocators;
import _tests.test_async;
import _tests.test_betterc;
import _tests.test_containers;
import _tests.test_io;
import _tests.test_parser;
import _tests.test_threads;
import _tests.test_utils;
import _tests.test_wasm;
import _tests.test_web;
import _tests.bench.bench;

enum RUN_SUBSET = false;

extern(C) void asm_test();

void main(string[] args) {
    string mode = args.length > 1 ? args[1] : "TEST";

    switch(mode) {
        case "BENCHMARK": {
            runBenchmarks();

            debug writefln("WARNING!!! Running benchmarks in debug mode\n");  
            return;
        }
        default:
            runTests();

            debug {} else writefln("WARNING!!! Running tests in release mode. Asserts are disabled\n");
            break;
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
void runTests() {
    writefln("Running tests");
    scope(failure) writefln("-- FAIL");
    scope(success) writeln("-- OK - All standard tests finished\n");

    static if(RUN_SUBSET) {

    } else {

        asm_test();

        testAllocators();
        testBetterc();
        testBool3();
        testContainers();
        testHasher();
        testIo();
        testParser();
        //testPDH();
        testStringBuffer();
        testStructCache();
        testThreads();
        testUtils();
        testVelocity();
        testWasm();
        testWeb();

        runAsyncTests();
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

    for(auto i=0; i<5; i++) {
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
        assert(buf.length==0 && buf.isEmpty());
        buf.add('a')
           .add("bc");
        buf ~= 'd';
        buf ~= "ef";
        assert(buf=="abcdef" && buf.length==6 && !buf.isEmpty());
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
    {   // slice, sliceDup
        auto buf = new StringBuffer("abcdef");
        auto s = buf.slice();
        auto s2 = buf.sliceDup();
        assert(s=="abcdef");
        assert(s2=="abcdef");

        buf.insert('.', 0);

        assert(s==".abcde", "actual = %s".format(s));    // takes on new value
        assert(s2=="abcdef");   // does not take on new value
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
