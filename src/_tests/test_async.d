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

void runAsyncTests() {
    writefln("Running async tests");
    scope(exit) writefln("Async tests finished");

    testAsyncQueue();
    //testAsyncArray();
}
// ======================================================
class AsyncWorkerBase {
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
    void run() {
        while(true) {
            atomicStore(_isWaiting, true);
            _semaphore.wait();
            atomicStore(_isWaiting, false);

            if(!_running) return;
            work();
            atomicOp!"-="(workItems, 1);
        }
    }
    bool isWaiting() { return atomicLoad(_isWaiting); }
    void doSomeWork(int count) {
        atomicOp!"+="(workItems, count);

        for(auto i=0; i<count; i++) {
            _semaphore.notify();
        }
    }
    void await() {
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
            this.popped.assumeSafeAppend();
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
            this.popped.assumeSafeAppend();
            this.popped.reserve(100_000);
        }
        override void work() {
            int[5] array;
            q.drain(array);
            popped ~= array;
        }
    }

    void testPushPop(IQueue!int q, int numProducers, int numConsumers) {
        Producer[] producers;
        PopConsumer[] consumers;
        const INITIAL    = 400_000;
        const BATCHES    = 1000;

        assert(INITIAL%numProducers==0);
        assert(INITIAL%numConsumers==0);
        assert(400%numProducers==0);
        assert(400%numConsumers==0);
        int producerBatchSize = 400 / numProducers;
        int consumerBatchSize = 400 / numConsumers;

        // inital rubbish
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

        producers.each!(it=>it.await);
        consumers.each!(it=>it.await);

        writefln("done");

        auto total1    = BATCHES*numConsumers*consumerBatchSize;
        auto total2    = BATCHES*numProducers*producerBatchSize;
        auto numPopped = consumers.map!(it=>it.popped.length).sum();
        auto popped    = consumers.map!(it=>it.popped.dup).join();
        sort(popped);

        popped     = popped[INITIAL..$];
        numPopped -= INITIAL;

        assert(q.length==0);
        assert(total1==total2);
        assert(numPopped==total1);

        for(int i=0; i<numPopped; i++) {
            assert(popped[i] == i/numProducers);
        }
    }
    void testDrain(IQueue!int q, int numProducers, int numConsumers) {
        Producer[] producers;
        DrainConsumer[] consumers;
        const INITIAL    = 1_000_000;
        const BATCHES    = 1000;

        assert(INITIAL%numProducers==0);
        assert(INITIAL%numConsumers==0);
        assert(400%numProducers==0);
        assert(400%numConsumers==0);
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

//        writefln("total1=%s", total1);
//        writefln("total2=%s", total2);
//        writefln("numPopped=%s", numPopped);
//        writefln("length=%s", q.length);

        assert(q.length==0);
        assert(total1==total2);
        assert(numPopped==total1);

        for(int i=0; i<numPopped; i++) {
            assert(popped[i] == i/numProducers);
        }
    }

    writefln("Testing push() and pop()");
    testPushPop(makeSPSCQueue!int(1024*1024), 1, 1);
    testPushPop(makeSPMCQueue!int(1024*1024), 1, 4);
    testPushPop(makeMPSCQueue!int(1024*1024), 4, 1);
    testPushPop(makeMPMCQueue!int(1024*1024), 4, 4);

    writefln("Testing drain()");
    testDrain(makeSPSCQueue!int(1024*1024*16), 1, 1);
    testDrain(makeSPMCQueue!int(1024*1024*16), 1, 4);
    testDrain(makeMPSCQueue!int(1024*1024*16), 4, 1);
    testDrain(makeMPMCQueue!int(1024*1024*16), 4, 4);

    
}