module bench;

import common;
import core.stdc.stdlib         : malloc, calloc;
import core.atomic              : atomicLoad, atomicStore, atomicOp;
import core.thread              : Thread, thread_joinAll;
import core.memory              : GC;
import std.stdio                : File, writeln, writefln;
import std.datetime.stopwatch   : benchmark, StopWatch;
import std.random               : randomShuffle,uniform, Mt19937, unpredictableSeed;
import std.format               : format;
import std.algorithm.iteration  : permutations, map, sum, each;
import std.algorithm.sorting    : sort;
import std.algorithm.mutation   : reverse;
import std.typecons             : Tuple,tuple;
import std.range                : array,stride,join,iota;
import std.parallelism          : parallel, task;
import std.file                 : tempDir, remove, exists;
import std.conv                 : to;

void main() {
    version(LDC) {
        writefln("Running benchmarks (LDC)");

        testStringAppending();
        // testSimd();
        // benchmarkByteReader();
        // benchmarkAsyncArray();
        // benchmarkQueue();
        // benchmarkAsyncQueue();
        // benchmarkAllocator();
        // benchmarkUtilities();
        // benchmarkArray();
        // benchmarkList();
        // benchmarkStructCache();

    } else {
        writefln("Running benchmarks (DMD)");

        //testSimd();
        testStringAppending();
    }
    writeln("All benchmarks finished");
}
pragma(inline,false)
void testSimd() {
    writefln("Testing SIMD #################################################");

    version(DMD) {
        import core.simd;
        import ldc.simd;

        float4 a = 0;
        float4 b = 1;

        float4 c = cast(float4)__simd(XMM.PXOR, a, a);
        float4 d = cast(float4)__simd(XMM.LODSS, c);

        __simd(XMM.LODAPS, a);


        writefln("%s", d);

    }

    writefln("Finished #####################################################");
}
void testStringAppending() {
    writefln("Testing String Appending #################################################");
    Mt19937 gen; gen.seed(0);
    StopWatch w;
    auto iterations = 1_000_000;

    writefln("%s", iterations%8);

    writefln("Preparing...");
    string[] strings =
        iota(0, iterations)
            .map!(it=>uniform(0, 100, gen))
            .map!(it=>"*".repeat(it))
            .array;

    GC.collect();

    string str;
    writefln("Start...");

    w.start();
    for(auto i=0; i<iterations; i+=8) {
        string a = strings[i];
        a ~= strings[i+1];
        a ~= strings[i+2];
        a ~= strings[i+3];
        a ~= strings[i+4];
        a ~= strings[i+5];
        a ~= strings[i+6];
        a ~= strings[i+7];
        str ~= a;

        //str ~= s;
    }
    w.stop();

    // 80

    writefln("%s", str.length);

    writefln("Elapsed %s millis", w.peek().total!"nsecs"/1000000.0);

    //
    auto buf = new StringBuffer();
    w.reset(); w.start();

    for(auto i=0; i<iterations; i+=8) {
        auto a = new StringBuffer()
            .add(strings[i])
            .add(strings[i+1])
            .add(strings[i+2])
            .add(strings[i+3])
            .add(strings[i+4])
            .add(strings[i+5])
            .add(strings[i+6])
            .add(strings[i+7]);
        buf.add(a.slice());
        //buf.add(s);
    }
    w.stop();
    writefln("%s", buf.length);
    writefln("Elapsed %s millis", w.peek().total!"nsecs"/1000000.0);

    //
    auto buf2 = new StringBuffer();
    w.reset(); w.start();

    for(auto i=0; i<iterations; i+=8) {
        auto a = tlStringBuffer()
            .add(strings[i])
            .add(strings[i+1])
            .add(strings[i+2])
            .add(strings[i+3])
            .add(strings[i+4])
            .add(strings[i+5])
            .add(strings[i+6])
            .add(strings[i+7]);
        buf2.add(a.sliceDup());
        //buf2.add(s);
    }
    w.stop();
    writefln("%s", buf2.length);
    writefln("Elapsed %s millis", w.peek().total!"nsecs"/1000000.0);

    writefln("Finished String Appending ################################################");
}

void benchmarkStructCache() {
    writefln("========--\nBenchmarking StructCache\n==--");
    auto iterations = 10_000_000;
    align(1) struct A {int[3] a; ubyte b;}
    auto cache = new StructCache!A(16, 1);
    A*[] ptrs; ptrs.length = iterations;
    uint pos;
    uint maxPos;
    Mt19937 gen; gen.seed(0);
    StopWatch w; w.start();
    for(auto i=0; i<iterations; i++) {
        if(pos<iterations-1 && (pos==0 || uniform(0, 100, gen)<54)) {
            ptrs[pos++] = cache.take();
            if(pos>maxPos) maxPos = pos;
        } else {
            cache.release(ptrs[--pos]);
        }
    }
    w.stop();
    writefln("maxPos=%s", maxPos); // 796686
    writefln("Elapsed %s millis", w.peek().total!"nsecs"/1000000.0);
    // 293.02 -> 306.92
}
void benchmarkList() {
    writefln("========--\nBenchmarking List\n==--");
    const J = 20;
    List!int b;

    pragma(inline,true)
    void addValues(uint count) {
        for(auto i=0; i<count;i++) b.add(i);
    }

    // linked list insert
    auto results = benchmark!({
        b = new List!int;
        addValues(10_000);
        // remove in the middle
        while(b.length<20_000) b.insert(99,5_000);
    })(J);
    // 1305.83 -> 1361.13
    writefln("LL insert .. took %.2f millis", results[0].total!"nsecs"/1000000.0);

    // linked list remove
    results = benchmark!({
        b = new List!int;
        addValues(10_000);
        // remove from the middle
        while(b.length>5_000) b.remove(5_000);
    })(J);
    // 533.30 -> 540.83
    writefln("LL remove .. took %.2f millis", results[0].total!"nsecs"/1000000.0);

}
void benchmarkArray() {
    writefln("========--\nBenchmarking Array\n==--");
    const J = 20;

    Array!int a;

    pragma(inline,true)
    void addValues(uint count) {
        for(auto i=0; i<count;i++) a.add(i);
    }

    // add
    auto results = benchmark!({
        a = new Array!int;
        addValues(10_000_000);
    })(J);
    // 730.44 -> 833.23
    writefln("add ..... took %.2f millis", results[0].total!"nsecs"/1000000.0);

    // remove
    results = benchmark!({
        a = new Array!int;
        addValues(10_000);
        // remove from the middle
        while(a.length>5_000) a.remove(5_000);
    })(J);
    // 16.57 -> 17.19
    writefln("remove .. took %.2f millis", results[0].total!"nsecs"/1000000.0);

    // insert
    results = benchmark!({
        a = new Array!int;
        addValues(10_000);
        // insert in the middle
        while(a.length<20_000) a.insertAt(99,5_000);
    })(J);
    // 189.76 -> 196.35
    writefln("insert .. took %.2f millis", results[0].total!"nsecs"/1000000.0);
}
void benchmarkUtilities() {
    writefln("========--\nBenchmarking utilities\n==--");
    // isZeroMem
    uint ptrLen = 10001;
    ubyte* ptr = cast(ubyte*)calloc(ptrLen, 1);
    ptr[ptrLen-2] = 0;
    ptr[ptrLen-1] = 0;
    uint iterations = 50_000;
    uint numRuns = 50;
    bool r;
    auto w = startTiming();
    for(auto iter=0; iter<numRuns; iter++) {
        for(auto i=0; i<iterations; i++) {
            r = isZeroMem(ptr, ptrLen);
        }
    }
    w.stop();
    writefln("r=%s", r);
    writefln("isZeroMem took %s millis", w.millis/numRuns);

    // onlyContains
    auto array  = new byte[10001];
    byte value = 0;
    array[] = value;
    //array[0] = 4;
    //array[array.length-1] = 4;
    w = startTiming();
    for(auto iter=0; iter<numRuns; iter++) {
        for(auto i=0; i<iterations; i++) {
            r = onlyContains(array.ptr, array.length, value);
        }
    }
    // 293.427 millis
    w.stop();
    writefln("r=%s", r);
    writefln("onlyContains took %s millis", w.millis/numRuns);

}
void benchmarkAllocator() {
    writefln("--== Benchmarking Allocator ==--");

    const uint N        = 1_000_000;
    const uint MAX_SIZE = 200;
    auto at = new Allocator(N);
    Mt19937 rng; rng.seed(0);
    Tuple!(uint,uint)[] add1;
    Tuple!(uint,uint)[] add2;
    Tuple!(uint,uint)[] free1a;
    Tuple!(uint,uint)[] free1b;
    Tuple!(uint,uint)[] free2;

    // alloc as much as we can
    while(at.numBytesFree > 500) {
        uint size   = uniform(1u, MAX_SIZE, rng);
        long offset = at.alloc(size);
        if(offset==-1) break;
        add1 ~= tuple(cast(uint)offset, size);
    }
    writefln("1) allocated %s regions", add1.length); flushConsole();
    auto num = at.numBytesFree();
    free1a = add1.dup;
    free1a.randomShuffle(rng);
    free1b = free1a[free1a.length/2..$].dup;
    free1a.length = free1a.length/2;
    auto num2 = at.numBytesFree();

    writefln("%s", at);

    // free half of them at random
    foreach(f; free1a) {
        static if(__traits(compiles,at.free(f[0]))) {
            at.free(f[0]);
        } else {
            at.free(f[0],f[1]);
        }
    }
    writefln("2) freed %s regions", free1a.length); flushConsole();

    // alloc again
    while(at.numBytesFree > 500) {
        uint size   = uniform(1u, MAX_SIZE, rng);
        long offset = at.alloc(size);
        if(offset==-1) break;
        add2 ~= tuple(cast(uint)offset, size);
    }
    writefln("3) allocated %s more regions", add2.length);
    free2 = add2.dup;
    free2.randomShuffle(rng);

    // free all
    foreach(f; free2) {
        static if(__traits(compiles,at.free(f[0]))) {
            at.free(f[0]);
        } else {
            at.free(f[0],f[1]);
        }
    }
    writefln("4) freed %s regions", free2.length);
    foreach(f; free1b) {
        static if(__traits(compiles,at.free(f[0]))) {
            at.free(f[0]);
        } else {
            at.free(f[0],f[1]);
        }
    }
    writefln("5) freed %s regions", free1b.length);
    writefln("free regions = %s, bytes=%s", at.numFreeRegions(), at.numBytesFree);
    writefln("%s", at);
    flushConsole();

    if(at.numBytesFree()!=N)
        throw new Error("woops!. numBytesFree=%s".format(at.numBytesFree));

    const J = 100;
    auto results = benchmark!({
        at.freeAll();

        // alloc1
        foreach(d; add1) {
            at.alloc(d[1]);
        }
        // free half
        foreach(f; free1a) {
            static if(__traits(compiles,at.free(f[0]))) {
                at.free(f[0]);
            } else {
                at.free(f[0],f[1]);
            }
        }

        // alloc2
        foreach(d; add2) {
            at.alloc(d[1]);
        }

        // free half
        foreach(f; free2) {
            static if(__traits(compiles,at.free(f[0]))) {
                at.free(f[0]);
            } else {
                at.free(f[0],f[1]);
            }
        }
        foreach(f; free1b) {
            static if(__traits(compiles,at.free(f[0]))) {
                at.free(f[0]);
            } else {
                at.free(f[0],f[1]);
            }
        }
    })(J);
    // with uints : 315.62 -> 334.85
    // with ulongs: 413 -> 416
    writefln("Allocator .. took %.2f millis", results[0].total!"nsecs"/1000000.0);
}
void benchmarkAsyncArray() {
    writefln("--== Benchmarking AsyncArray ==--");

}
void benchmarkQueue() {
    writefln("--== Benchmarking Queue ==--");

    const N = 8;
    Mt19937 rng; rng.seed(0);

    auto q = new Queue!int(2*1024*1024);
    StopWatch w;

    w.start();

    void run() {
        for(auto i=0; i<1_000_000; i++) {
            if(q.length<50 || uniform(0f,1f,rng) < 0.6f) {
                q.push(1);
            } else {
                q.pop();
            }
        }
    }

    foreach(i; iota(0,N)) {
        run();
    }

    w.stop();
    writefln("Took %.2f millis", w.peek().total!"nsecs"/1000000.0);
    // 53 -> 55
}
void benchmarkAsyncQueue() {
    writefln("--== Benchmarking AsyncQueue ==--");

    Mt19937 rng;
    StopWatch w;

    static class QBase {
        IQueue!int theQueue;
        Thread th;
        int factor;
        this(IQueue!int theQueue, int factor) {
            this.theQueue = theQueue;
            this.factor = factor;
            this.th = new Thread(&run);
            for(auto i=0; i<500_000; i++) theQueue.push(1);
            th.start();
        }
        void run() {
            for(auto i=0; i<1_000_000*factor; i++) {
                doThing();
            }
        }
        void await() {
            th.join();
        }
        abstract void doThing();
    }
    static class QProducer : QBase {
        this(IQueue!int theQueue, int factor) {
            super(theQueue, factor);
        }
        override void doThing() {
            theQueue.push(1);
        }
    }
    static class QConsumer : QBase {
        this(IQueue!int theQueue, int factor) {
            super(theQueue, factor);
        }
        override void doThing() {
            theQueue.pop();
        }
    }

    ulong timeIt(int numProducers, int numConsumers, IQueue!int q) {
        rng.seed(0);
        w.reset();
        w.start();

        QBase[] things;

        int producerFactor = 4/numProducers;
        int consumerFactor = 4/numConsumers;

        for(auto i=0; i<numProducers; i++) {
            things ~= new QProducer(q,producerFactor);
        }
        for(auto i=0; i<numConsumers; i++) {
            things ~= new QConsumer(q,consumerFactor);
        }
        things.each!(it=>it.await());

        w.stop();
        return w.peek().total!"nsecs";
    }

    ulong t1 = timeIt(1,1,
        new Queue!(int,ThreadingModel.SPSC)(1024*1024*4)
    );
    ulong t2 = timeIt(2,1,
        new Queue!(int,ThreadingModel.MPSC)(1024*1024*4)
    );
    ulong t3 = timeIt(1,2,
        new Queue!(int,ThreadingModel.SPMC)(1024*1024*4)
    );
    ulong t4 = timeIt(2,2,
        new Queue!(int,ThreadingModel.MPMC)(1024*1024*4)
    );

    writefln("Single producer single consumer queue: %.2f millis", t1/1000000.0);
    writefln("Multi producer single consumer queue : %.2f millis", t2/1000000.0);
    writefln("Single producer multi consumer queue : %.2f millis", t3/1000000.0);
    writefln("Multi producer multi consumer queue  : %.2f millis", t4/1000000.0);
    // 234 -> 281  37 -> 50
    // 332 -> 361
    // 340 -> 356 278 -> 322
    // 415 -> 456
}
void benchmarkByteReader() {
    writefln("--== Benchmarking ByteReader ==--");
    Mt19937 rng; rng.seed(0);

    void createTestData(string filename) {
        writefln("Creating test file '%s'", filename);
        scope f = File(filename, "wb");
        ubyte[20_000*15] data;
        for(auto i=0; i<data.length; i++) {
            data[i] = cast(ubyte)uniform(0,255,rng);
        }
        f.rawWrite(data);
        f.close();
    }

    string dir = tempDir();
    string filename = dir~"benchmarkByteReader.bin";
    if(!exists(filename)) createTestData(filename);

    ulong total;
    auto r = new FileByteReader(filename);
    auto results = benchmark!({
        r.rewind();

        for(auto i=0; i<20_000; i++) {
            total += r.read!ubyte;
            total += r.read!ushort;
            total += r.read!uint;
            total += r.read!ulong;
        }
        expect(r.position <= r.length);

    })(100);
    // 33 40
    // --

    writefln("ByteReader took %s millis", results[0].total!"nsecs"/1000000.0);
}