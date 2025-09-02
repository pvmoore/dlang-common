module _tests.test_async;

import std.stdio;
import core.thread;
import core.atomic;
import core.time;
import core.sync.semaphore;
import std.array;
import std.algorithm.iteration : map, sum, each;
import std.algorithm.sorting   : sort;

import common;
import common.containers;
import common.io;
import common.utils;

void runAsyncTests() {
    writefln("Running async tests");
    scope(exit) writefln("Async tests finished");

    testAsyncQueue();
    testAsyncArray();
}
// ======================================================
abstract class AsyncWorkerBase {
    Thread _thread;
    Semaphore _semaphore;
    bool _running = true;
    shared bool _isWaiting;
    shared int workItems;

    this() {
        this._semaphore = new Semaphore;
        this._thread = new Thread(&run);
        _thread.start();
    }
    final void run() {
        while(true) {
            atomicStore(_isWaiting, true);
            _semaphore.wait();
            atomicStore(_isWaiting, false);

            if(!_running) return;
            work();
            atomicOp!"-="(workItems, 1);
        }
    }
    final bool isWaiting() { 
        return atomicLoad(_isWaiting); 
    }
    final void doSomeWork(int count) {
        atomicOp!"+="(workItems, count);

        for(auto i=0; i<count; i++) {
            _semaphore.notify();
        }
    }
    final void await() {
        while(_running && atomicLoad(workItems)>0) {
            Thread.sleep(dur!"msecs"(10));
        }
        _running = false;
        _semaphore.notify();
    }
    abstract void work();
}
// ======================================================
void testAsyncArray() {
    writefln("--== Testing AsyncArray ==--");

    auto a = new AsyncArray!int;
    assert(a.length==0 && a.empty);

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
}
void testAsyncQueue() {
    writefln("--== Testing AsyncQueue ==--");

    static final class Producer : AsyncWorkerBase {
        IQueue!int q;
        int counter;
        this(IQueue!int q) {
            this.q = q;
        }
        override void work() {
            q.push(counter++);
        }
    }
    static final class PopConsumer : AsyncWorkerBase {
        IQueue!int q;
        int[] popped;
        this(IQueue!int q) {
            this.q = q;
            this.popped.reserve(100_000);
        }
        override void work() {
            popped ~= q.pop();
        }
    }
    static final class DrainConsumer : AsyncWorkerBase {
        IQueue!int q;
        int[] popped;
        this(IQueue!int q) {
            this.q = q;
            this.popped.reserve(100_000);
        }
        override void work() {
            int[5] array;
            auto count = q.drain(array);
            popped ~= array[0..count];
        }
    }

    void testPushPop(IQueue!int q, int numProducers, int numConsumers) {
        writefln("Testing push() and pop() with %s producers and %s consumers", numProducers, numConsumers);
        Producer[] producers;
        PopConsumer[] consumers;
        const INITIAL = 400_000;
        const BATCHES = 1000;

        throwIfNot(INITIAL%numProducers==0);
        throwIfNot(INITIAL%numConsumers==0);
        throwIfNot(400%numProducers==0);
        throwIfNot(400%numConsumers==0);
        int producerBatchSize = 400 / numProducers;
        int consumerBatchSize = 400 / numConsumers;

        // initial rubbish
        for(auto i=0; i<INITIAL; i++) {
            q.push(-1);
        }

        for(auto i=0; i<numProducers; i++) {
            producers ~= new Producer(q);
        }
        for(auto i=0; i<numConsumers; i++) {
            consumers ~= new PopConsumer(q);
        }

        for(auto i=0; i<BATCHES; i++) {
            producers.each!(it=>it.doSomeWork(producerBatchSize));
            consumers.each!(it=>it.doSomeWork(consumerBatchSize));
        }
        consumers.each!(it=>it.doSomeWork(INITIAL/numConsumers));


        writef("waiting ... ");
        flushConsole();

        producers.each!(it=>it.await());
        consumers.each!(it=>it.await());

        writefln("done");

        auto total1    = BATCHES*numConsumers*consumerBatchSize;
        auto total2    = BATCHES*numProducers*producerBatchSize;
        auto numPopped = consumers.map!(it=>it.popped.length).sum();
        auto popped    = consumers.map!(it=>it.popped.dup).join();
        sort(popped);

        popped     = popped[INITIAL..$];
        numPopped -= INITIAL;

        throwIfNot(q.length==0);
        throwIfNot(total1==total2);
        throwIfNot(numPopped==total1);

        for(int i=0; i<numPopped; i++) {
            throwIfNot(popped[i] == i/numProducers);
        }
    }
    void testDrain(IQueue!int q, int numProducers, int numConsumers) {
        writefln("Testing drain() with %s producers and %s consumers", numProducers, numConsumers);
        Producer[] producers;
        DrainConsumer[] consumers;
        const INITIAL    = 1_000_000;
        const BATCHES    = 1000;

        throwIfNot(INITIAL%numProducers==0);
        throwIfNot(INITIAL%numConsumers==0);
        throwIfNot(400%numProducers==0);
        throwIfNot(400%numConsumers==0);
        int producerBatchSize = 400 / numProducers;
        int consumerBatchSize = 80 / numConsumers;

        // initial rubbish
        for(auto i=0; i<INITIAL; i++) {
            q.push(-1);
        }

        for(auto i=0; i<numProducers; i++) {
            producers ~= new Producer(q);
        }
        for(auto i=0; i<numConsumers; i++) {
            consumers ~= new DrainConsumer(q);
        }

        for(auto i=0; i<BATCHES; i++) {
            producers.each!(it=>it.doSomeWork(producerBatchSize));
            consumers.each!(it=>it.doSomeWork(consumerBatchSize));
        }
        consumers.each!(it=>it.doSomeWork((INITIAL/5)/numConsumers));

        writef("waiting ... ");
        flushConsole();

        producers.each!(it=>it.await);
        consumers.each!(it=>it.await);

        writefln("done");

        auto total1    = 5*BATCHES*numConsumers*consumerBatchSize;
        auto total2    = BATCHES*numProducers*producerBatchSize;
        auto numPopped = consumers.map!(it=>it.popped.length).sum();
        auto popped    = consumers.map!(it=>it.popped.dup).join();
        sort(popped);

        popped     = popped[INITIAL..$];
        numPopped -= INITIAL;

    //    writefln("total1=%s", total1);
    //    writefln("total2=%s", total2);
    //    writefln("numPopped=%s", numPopped);
    //    writefln("length=%s", q.length);

        throwIfNot(q.length==0);
        throwIfNot(total1==total2);
        throwIfNot(numPopped==total1);

        for(int i=0; i<numPopped; i++) {
            throwIfNot(popped[i] == i/numProducers);
        }
        writefln("Assertions PASSED");
    }

    debug {
        enum doBenchmark = false;
    } else {
        enum doBenchmark = true;
        import std.datetime.stopwatch : StopWatch;
        StopWatch w; w.start();
    }

    enum C = 16; // cores
    testPushPop(makeSPSCQueue!int(1024*1024), 1, 1);
    testPushPop(makeSPMCQueue!int(1024*1024), 1, C);
    testPushPop(makeMPSCQueue!int(1024*1024), C, 1);
    testPushPop(makeMPMCQueue!int(1024*1024), C, C);

    testDrain(makeSPSCQueue!int(1024*1024*16), 1, 1);
    testDrain(makeSPMCQueue!int(1024*1024*16), 1, C);
    testDrain(makeMPSCQueue!int(1024*1024*16), C, 1);
    testDrain(makeMPMCQueue!int(1024*1024*16), C, C);

    static if(doBenchmark) {
        w.stop();
        writefln("╔═════════════════════════════════════════════════════════════════════");
        writefln("║ Took %.2f millis", w.peek().total!"nsecs"/1_000_000.0);
        writefln("╚═════════════════════════════════════════════════════════════════════");
    }
}
