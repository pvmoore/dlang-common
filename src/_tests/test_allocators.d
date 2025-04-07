module _tests.test_allocators;

import std.stdio;
import std.random             : uniform, uniform01, Mt19937, unpredictableSeed, randomShuffle;
import std.typecons           : tuple, Tuple;
import std.datetime.stopwatch : StopWatch, AutoStart;

import common;
import common.allocators;
import _tests.test;

void testAllocators() {
    writefln("--== Testing Allocators ==--");
    static if(RUN_SUBSET) {
       
    } else {
        testFreeList();
        testStaticFreeList();
        testBasicAllocator();
        testArenaAllocator();
        testStructStorage();
        testHeapStorage();

        fuzzTestAllocator();
    }
}

void testFreeList() {
    writefln("--== Testing FreeList ==--");

    {
        writef(" Create");
        auto fl = new FreeList(8);
        assert(fl.numUsed() == 0);
        assert(fl.numFree() == 8);
        writefln(" OK");
    }
    {
        writef(" Acquire");
        auto fl = new FreeList(4);
        assert(fl.acquire() == 0);
        assert(fl.numUsed() == 1);
        assert(fl.numFree() == 3);

        assert(fl.acquire() == 1);
        assert(fl.numUsed() == 2);
        assert(fl.numFree() == 2);

        assert(fl.acquire() == 2);
        assert(fl.numUsed() == 3);
        assert(fl.numFree() == 1);

        assert(fl.acquire() == 3);
        assert(fl.numUsed() == 4);
        assert(fl.numFree() == 0);

        try{
            fl.acquire();
            assert(false);
        }catch(Exception e) {}
        writefln(" OK");
    }
    {
        writefln(" Acquire/Release forward");
        auto fl = new FreeList(4);
        uint a = fl.acquire();
        uint b = fl.acquire();
        uint c = fl.acquire();
        uint d = fl.acquire();
        assert(fl.numUsed() == 4);
        assert(fl.numFree() == 0);

        fl.release(a);
        fl.release(b);
        fl.release(c);
        fl.release(d); 
        assert(fl.numUsed() == 0);
        assert(fl.numFree() == 4);  
    }
    {
        writefln(" Acquire/Release reverse");
        auto fl = new FreeList(4);
        uint a = fl.acquire();
        uint b = fl.acquire();
        uint c = fl.acquire();
        uint d = fl.acquire();
        assert(fl.numUsed() == 4);
        assert(fl.numFree() == 0);

        fl.release(d);
        fl.release(c);
        fl.release(b);
        fl.release(a); 
        assert(fl.numUsed() == 0);
        assert(fl.numFree() == 4);
    }
    {
        writefln(" Acquire/Release mixed");
        auto fl = new FreeList(4);
        uint a = fl.acquire();
        uint b = fl.acquire();
        uint c = fl.acquire();
        uint d = fl.acquire();
        assert(fl.numUsed() == 4);
        assert(fl.numFree() == 0);

        fl.release(c);
        fl.release(a);
        fl.release(d);
        fl.release(b); 
        assert(fl.numUsed() == 0);
        assert(fl.numFree() == 4);
    }
    {
        writefln(" Acquire/Release mixed 2");
        auto fl = new FreeList(4);
        uint a = fl.acquire();
        uint b = fl.acquire();
        assert(fl.numUsed() == 2);
        assert(fl.numFree() == 2);

        fl.release(b);
        assert(fl.numUsed() == 1);
        assert(fl.numFree() == 3);

        uint c = fl.acquire();
        assert(fl.numUsed() == 2);
        assert(fl.numFree() == 2);

        fl.release(a);
        assert(fl.numUsed() == 1);
        assert(fl.numFree() == 3);

        uint d = fl.acquire();
        assert(fl.numUsed() == 2);
        assert(fl.numFree() == 2);

        fl.release(c);
        assert(fl.numUsed() == 1);
        assert(fl.numFree() == 3);
    }
    {
        void _fuzzit(uint size, float pivot) {
            writef(" - Fuzzing FreeList(%s) pivot %s".format(size, pivot));
            auto fl = new FreeList(size);
            bool[] used = new bool[size];
            uint[] acquired;
            uint iterations = size*100;

            for(auto i=0; i<iterations; i++) {
                auto r = uniform01();

                if(r < pivot) {
                    // release
                    if(acquired.length > 0) {
                        uint n = uniform(0, acquired.length.as!uint);
                        uint k = acquired[n];
                        fl.release(k);
                        acquired.removeAt(n);

                        assert(used[k] == true);
                        used[k] = false;
                    }
                } else {
                    // acquire
                    if(fl.numFree() > 0) {
                        uint k = fl.acquire();
                        assert(used[k] == false);
                        used[k] = true;
                        acquired ~= k;

                    }
                }
            }
            writefln("  :: (%s iteratioms), Used %s slots".format(iterations, fl.numUsed()));
        }
        writefln(" Fuzz");
        _fuzzit(10, 0.25);
        _fuzzit(10, 0.5);
        _fuzzit(10, 0.75);

        _fuzzit(100, 0.25);
        _fuzzit(100, 0.5);
        _fuzzit(100, 0.75);
    }
}

void testStaticFreeList() {
    writefln("--== Testing StaticFreeList ==--");

    {
        writef(" Create");
        StaticFreeList!8 fl;
        assert(fl.numUsed() == 0);
        assert(fl.numFree() == 8);
        assert(fl.size() == 8);
        writefln(" OK");
    }
    {
        writef(" Acquire");
        StaticFreeList!4 fl;
        assert(fl.acquire() == 0);
        assert(fl.numUsed() == 1);
        assert(fl.numFree() == 3);

        assert(fl.acquire() == 1);
        assert(fl.numUsed() == 2);
        assert(fl.numFree() == 2);

        assert(fl.acquire() == 2);
        assert(fl.numUsed() == 3);
        assert(fl.numFree() == 1);

        assert(fl.acquire() == 3);
        assert(fl.numUsed() == 4);
        assert(fl.numFree() == 0);

        try{
            fl.acquire();
            assert(false);
        }catch(Exception e) {}
        writefln(" OK");
    }
    {
        writefln(" Acquire/Release forward");
        StaticFreeList!4 fl;
        uint a = fl.acquire();
        uint b = fl.acquire();
        uint c = fl.acquire();
        uint d = fl.acquire();
        assert(fl.numUsed() == 4);
        assert(fl.numFree() == 0);

        fl.release(a);
        fl.release(b);
        fl.release(c);
        fl.release(d); 
        assert(fl.numUsed() == 0);
        assert(fl.numFree() == 4);  
    }
    {
        writefln(" Acquire/Release reverse");
        StaticFreeList!4 fl;
        uint a = fl.acquire();
        uint b = fl.acquire();
        uint c = fl.acquire();
        uint d = fl.acquire();
        assert(fl.numUsed() == 4);
        assert(fl.numFree() == 0);

        fl.release(d);
        fl.release(c);
        fl.release(b);
        fl.release(a); 
        assert(fl.numUsed() == 0);
        assert(fl.numFree() == 4);
    }
    {
        writefln(" Acquire/Release mixed");
        StaticFreeList!4 fl;
        uint a = fl.acquire();
        uint b = fl.acquire();
        uint c = fl.acquire();
        uint d = fl.acquire();
        assert(fl.numUsed() == 4);
        assert(fl.numFree() == 0);

        fl.release(c);
        fl.release(a);
        fl.release(d);
        fl.release(b); 
        assert(fl.numUsed() == 0);
        assert(fl.numFree() == 4);
    }
    {
        writefln(" Acquire/Release mixed 2");
        StaticFreeList!4 fl;
        uint a = fl.acquire();
        uint b = fl.acquire();
        assert(fl.numUsed() == 2);
        assert(fl.numFree() == 2);

        fl.release(b);
        assert(fl.numUsed() == 1);
        assert(fl.numFree() == 3);

        uint c = fl.acquire();
        assert(fl.numUsed() == 2);
        assert(fl.numFree() == 2);

        fl.release(a);
        assert(fl.numUsed() == 1);
        assert(fl.numFree() == 3);

        uint d = fl.acquire();
        assert(fl.numUsed() == 2);
        assert(fl.numFree() == 2);

        fl.release(c);
        assert(fl.numUsed() == 1);
        assert(fl.numFree() == 3);
    }
    {
        void _fuzzit(uint SIZE)(float pivot) {
            writef(" - Fuzzing FreeList(%s) pivot %s".format(SIZE, pivot));
            StaticFreeList!SIZE fl;
            bool[] used = new bool[SIZE];
            uint[] acquired;
            uint iterations = SIZE*100;

            for(auto i=0; i<iterations; i++) {
                auto r = uniform01();

                if(r < pivot) {
                    // release
                    if(acquired.length > 0) {
                        uint n = uniform(0, acquired.length.as!uint);
                        uint k = acquired[n];
                        fl.release(k);
                        acquired.removeAt(n);

                        assert(used[k] == true);
                        used[k] = false;
                    }
                } else {
                    // acquire
                    if(fl.numFree() > 0) {
                        uint k = fl.acquire();
                        assert(used[k] == false);
                        used[k] = true;
                        acquired ~= k;

                    }
                }
            }
            writefln("  :: (%s iteratioms), Used %s slots".format(iterations, fl.numUsed()));
        }
        writefln(" Fuzz");
        _fuzzit!10(0.25);
        _fuzzit!10(0.5);
        _fuzzit!10(0.75);

        _fuzzit!100(0.25);
        _fuzzit!100(0.5);
        _fuzzit!100(0.75);
    }
}

void testBasicAllocator() {
    writefln("--== Testing Basic Allocator ==--");

    {   
        writef(" Empty Allocator");
        auto a = new BasicAllocator(0);
        expect(a.isEmpty());
        expect(a.size()==0);
        expect(a.numBytesFree()==0);
        expect(a.numBytesUsed()==0);
        expect(a.numFreeRegions()==1);
        auto fr = a.freeRegions();
        expect(fr.length==1);
        expect(fr[0][0]==0 && fr[0][1]==0);

        /// try to allocate 10
        expect(-1 == a.alloc(10));

        /// resize
        a.resize(100);
        expect(a.isEmpty());
        expect(a.size()==100);
        expect(a.numBytesFree()==100);
        expect(a.numBytesUsed()==0);
        expect(a.numFreeRegions()==1);
        fr = a.freeRegions();
        expect(fr.length==1);
        expect(fr[0][0]==0 && fr[0][1]==100, "freeRegions = %s".format(fr));

        /// Allocate 10
        expect(0 == a.alloc(10));

        expect(!a.isEmpty());
        expect(a.size()==100);
        expect(a.numBytesFree()==90);
        expect(a.numBytesUsed()==10);
        expect(a.numFreeRegions()==1);
        fr = a.freeRegions();
        expect(fr.length==1);
        expect(fr[0][0]==10 && fr[0][1]==90);

        writefln(" OK");
    }
    {
        writef(" Freeing");
        auto a = new BasicAllocator(100);
        expect(0==a.alloc(50));
        expect(a.numFreeRegions()==1);
        // |xxxxx.....|

        a.free(10, 20);
        // |x..xx.....|
        expect(a.numBytesFree()==70);
        expect(a.getFreeRegionsByOffset()==[tuple(10,20), tuple(50,50)]);

        a.free(40,10);
        // |x..x......|
        expect(a.numBytesFree()==80);
        expect(a.getFreeRegionsByOffset()==[tuple(10,20), tuple(40,60)]);

        writefln(" OK");
    }

    {   
        writef(" Basic properties");
        auto a = new BasicAllocator(100);

        expect(a.numBytesFree==100);
        expect(a.numBytesUsed==0);
        expect(a.numFreeRegions==1);
        expect(a.freeRegions[0]==tuple(0,100));
        writefln(" OK");
    }

    {   
        writef(" Resizing");
        auto a = new BasicAllocator(100);
        a.alloc(10);

        // expand where there is a free region at the end
        a.resize(200);

        expect(a.numBytesFree==190);
        expect(a.numBytesUsed==10);
        expect(a.numFreeRegions==1);
        expect(a.freeRegions[0]==tuple(10,190));

        a.reset();
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
        a.reset();

        // reduce where there is a free region at the end
        // | 50 used | 250 free | (size=300)
        a.alloc(50);
        expect(a.freeRegions==[tuple(50,250)]);
        expect(a.size()==300);

        a.resize(250);
        // | 50 used | 200 free | (size=250)
        expect(a.size()==250);
        expect(a.numBytesFree==200);
        expect(a.numBytesUsed==50);
        expect(a.numFreeRegions==1);
        expect(a.freeRegions==[tuple(50,200)]);

        // reduce so that the last free region is removed
        a.resize(50);
        // | 50 used | (size=50)
        expect(a.size()==50);
        expect(a.numBytesFree==0);
        expect(a.numBytesUsed==50);
        expect(a.numFreeRegions==0);
        expect(a.freeRegions==[]);

        // attempt to reduce where end of alloc memory is in use
        a.resize(45);
        expect(a.size()==50);

        writefln(" OK");
    }
}

void testArenaAllocator() {
    writefln("--== Testing Arena Allocator ==--");

    {
        writef(" Empty Allocator");
        auto a = new ArenaAllocator(0);
        expect(a.numBytesUsed() == 0);
        expect(a.numBytesFree() == 0);
        
        expect(a.alloc(1) == -1);
        writefln(" OK");
    }
    {
        writef(" Alloc alignment = 1");
        auto a = new ArenaAllocator(100);
        expect(a.numBytesUsed() == 0);
        expect(a.numBytesFree() == 100);

        expect(a.alloc(10) == 0);
        expect(a.numBytesUsed() == 10);
        expect(a.numBytesFree() == 90);

        expect(a.alloc(20) == 10);
        expect(a.numBytesUsed() == 30);
        expect(a.numBytesFree() == 70);

        expect(a.alloc(71) == -1);
    }
    {
        writef(" Alloc alignment = 4");
        auto a = new ArenaAllocator(100);
        expect(a.numBytesUsed() == 0);
        expect(a.numBytesFree() == 100);

        expect(a.alloc(10, 4) == 0);
        expect(a.numBytesUsed() == 10);
        expect(a.numBytesFree() == 90);

        expect(a.alloc(21, 4) == 12);
        expect(a.numBytesUsed() == 33);
        expect(a.numBytesFree() == 67);

        expect(a.alloc(5, 4) == 36);
        expect(a.numBytesUsed() == 41);
        expect(a.numBytesFree() == 59);

        expect(a.alloc(60, 4) == -1);
    }
    {
        writef(" Alloc alignment = 8");
        auto a = new ArenaAllocator(100);
        expect(a.numBytesUsed() == 0);
        expect(a.numBytesFree() == 100);

        expect(a.alloc(10, 8) == 0);
        expect(a.numBytesUsed() == 10);
        expect(a.numBytesFree() == 90);

        expect(a.alloc(21, 8) == 16);
        expect(a.numBytesUsed() == 37);
        expect(a.numBytesFree() == 63);
    }
    {
        writef(" Free");
        auto a = new ArenaAllocator(100);

        expect(a.alloc(20)==0);
        expect(a.numBytesUsed() == 20);
        expect(a.numBytesFree() == 80);

        // No change
        a.free(0, 20);
        expect(a.numBytesUsed() == 20);
        expect(a.numBytesFree() == 80);
    }
    {
        writef(" Reset");
        auto a = new ArenaAllocator(100);
        expect(a.numBytesUsed() == 0);
        expect(a.numBytesFree() == 100);

        expect(a.alloc(20)==0);
        expect(a.numBytesUsed() == 20);
        expect(a.numBytesFree() == 80);

        a.reset();
        expect(a.numBytesUsed() == 0);
        expect(a.numBytesFree() == 100);
    }
    {
        writef(" Resize");
        auto a = new ArenaAllocator(100);
        expect(a.numBytesUsed() == 0);
        expect(a.numBytesFree() == 100);

        expect(a.alloc(20)==0);
        expect(a.numBytesUsed() == 20);
        expect(a.numBytesFree() == 80);

        a.resize(1000);
        expect(a.numBytesUsed() == 20);
        expect(a.numBytesFree() == 980);
    }
}

void testStructStorage() {
    writefln("--== Testing StructStorage ==--");

    static struct S {
        int x;
    }

    {
        writef(" Empty");
        auto a = new StructStorage!S(0);
        expect(a.numUsed() == 0);
        expect(a.numFree() == 0);
        
        writefln(" OK");
    }
    {
        writef(" Alloc");
        auto ss = new StructStorage!S(10);
        expect(ss.numUsed() == 0);
        expect(ss.numFree() == 10);

        S* a = ss.alloc();
        expect(a !is null);
        expect(ss.numUsed() == 1);
        expect(ss.numFree() == 9);

        S* b = ss.alloc();
        expect(b !is null);
        expect(ss.numUsed() == 2);
        expect(ss.numFree() == 8);
    }
    {
        writef(" Free");
        auto ss = new StructStorage!S(10);
        expect(ss.numUsed() == 0);
        expect(ss.numFree() == 10);
        S* a = ss.alloc();
        expect(a !is null);
        a.x = 1;

        ss.free(a);
        expect(ss.numUsed() == 0);
        expect(ss.numFree() == 10);

        // a now points to a reset S instance
        expect(a.x == 0);
    }
}
void testHeapStorage() {
    writefln("--== Testing HeapStorage ==--");

    {
        writef(" Empty");
        auto a = new HeapStorage(new ArenaAllocator(0));
        expect(a.size() == 0);
        expect(a.numBytesUsed() == 0);
        expect(a.numBytesFree() == 0);

        expect(a.alloc(1) is null);
        
        writefln(" OK");
    }
    {
        writef(" Alloc");
        auto a = new HeapStorage(new ArenaAllocator(100));
        expect(a.size() == 100);
        expect(a.numBytesUsed() == 0);
        expect(a.numBytesFree() == 100);

        void* p1 = a.alloc(10);
        expect(p1 !is null);
        expect(a.size() == 100);
        expect(a.numBytesUsed() == 10);
        expect(a.numBytesFree() == 90);

        void* p2 = a.alloc(20);
        expect(p2 !is null);
        expect(a.size() == 100);
        expect(a.numBytesUsed() == 30);
        expect(a.numBytesFree() == 70);

        void* p3 = a.alloc(71);
        expect(p3 is null);

        void* p4 = a.alloc(10);
        expect(p4 !is null);
        expect(a.size() == 100);
        expect(a.numBytesUsed() == 40);
        expect(a.numBytesFree() == 60);
    }
    {
        writef(" Free");
        auto a = new HeapStorage(new BasicAllocator(100));
        expect(a.size() == 100);
        expect(a.numBytesUsed() == 0);
        expect(a.numBytesFree() == 100);

        void* p1 = a.alloc(10);
        expect(p1 !is null);
        expect(a.numBytesUsed() == 10);
        expect(a.numBytesFree() == 90);

        void* p2 = a.alloc(20);
        expect(p2 !is null);
        expect(a.numBytesUsed() == 30);
        expect(a.numBytesFree() == 70);

        ubyte* p1b = p1.as!(ubyte*);
        p1b[0] = 7;

        a.free(p1);
        expect(a.numBytesUsed() == 20);
        expect(a.numBytesFree() == 80);

        // the freed memory has been zeroed
        expect(p1b[0] == 0);
    }
    {
        writef(" Reset");
        auto a = new HeapStorage(new BasicAllocator(100));

        void* p = a.alloc(10);
        ubyte* pb = p.as!(ubyte*);
        expect(p !is null);
        expect(a.numBytesUsed() == 10);
        expect(a.numBytesFree() == 90);

        pb[0] = 99;

        a.reset();
        expect(a.numBytesUsed() == 0);
        expect(a.numBytesFree() == 100);

        // The memory has been zeroed
        expect(pb[0] == 0);
    }
}

/**
 * Randomly allocate and free memory using the given allocator
 */
void fuzzTestAllocator() {
    writefln("----------------------------------------------------------------");
    writefln("Fuzz Testing");
    writefln("----------------------------------------------------------------");

    // Size 10000, took 23.4731 millis
    // Size 100000, took 75.7526 millis
    // Size 1000000, took 495.426 millis

    fuzzTest(new BasicAllocator(10_000));
    fuzzTest(new BasicAllocator(100_000));
    fuzzTest(new BasicAllocator(1_000_000));
}
void fuzzTest(Allocator allocator) {
    static struct Regn { 
        ulong offset;
        ulong size; 
    }
    static struct Data {
        ubyte[] data;       // 0 represents free, 1 represents used
        Regn[] alloced;

        this(ulong size) {
            data = new ubyte[size];
        }
        void reset() {
            data[] = 0;
            alloced.length = 0;
        }
        void allocRange(ulong offset, ulong size) {
            foreach(i; offset..offset+size) {
                throwIf(data[i]==1, "bad alloc: Offset %s is already allocated", i);
            }
            alloced ~= Regn(offset, size);
            data[offset..offset+size] = 1;
        }
        // free 'size' bytes in 'data' starting at 'offset'
        void free(ulong offset, ulong size) {
            foreach(i; offset..offset+size) {
                throwIf(data[i]==0, "bad free: Offset %s is already free", i);
            }
            import std.algorithm : remove;
            data[offset..offset+size] = 0;
            alloced.removeFirstMatch!Regn(it=> it.offset==offset && it.size==size);
        }
        void check(Allocator allocator) {
            BasicAllocator basic = allocator.as!BasicAllocator;
            throwIf(!basic, "Handle allocator %s", allocator);

            foreach(i; 0..data.length) {
                throwIf(isAllocated(i) != basic.isAllocated(i));
            }
        }
        bool isAllocated(ulong offset) {
            return data[offset]==1;
        }
        ulong numBytesFree() {
            import std.algorithm : count;
            return data.count!"a==0";
        }
        ulong numBytesUsed() {
            return data.length - numBytesFree();
        }
        void dumpRegions() {
            writefln("Allocated regions:");
            foreach(r; alloced) {
                writefln("  (%s - %s)", r.offset, r.offset + r.size-1);
            }
        }
    }

    Mt19937 rng;
    uint seed = unpredictableSeed;
    ulong SIZE = allocator.size(); 
    enum ITERATIONS    = 10; 
    enum MAX_ALIGNMENT = 16;
    enum minAllocSize  = 1;
    ulong maxAllocSize = SIZE / 500;

    enum VERBOSE = false;
    version(D_Optimized) {
        enum BENCHMARK = true;
    } else {
        enum BENCHMARK = false;
    }
    Data data = Data(SIZE);
    rng.seed(seed);

    static if(VERBOSE) { 
        writefln("Size .. %s", SIZE);
        writefln("Seed .. %s", seed);
    }

    StopWatch watch = StopWatch(AutoStart.yes);

    for(auto j=0; j<ITERATIONS; j++) {
        static if(!BENCHMARK) {
            writefln("===============================================================");
            writefln("Iteration %s", j+1);
            writefln("===============================================================");
        }
        for(uint alignment = 1; alignment <= MAX_ALIGNMENT; alignment *= 2) {
            static if(!BENCHMARK) {
                writefln("");
                writefln(" Alignment               = %s", alignment);
                writefln("  data.numBytesFree      = %s (%s used)", data.numBytesFree(), data.numBytesUsed());
                writefln("  allocator.numBytesFree = %s (%s used)", allocator.numBytesFree(), allocator.numBytesUsed());
                writefln("  ---------------------------------------------------------------");
            }
            // allocate as much as possible
            static if(!BENCHMARK) writef("  Allocating randomly...");
            
            while(true) {
                ulong size = uniform(minAllocSize, maxAllocSize, rng);

                long offset = allocator.alloc(size, alignment);
                if(offset == -1) { 
                    break; 
                }
                static if(VERBOSE) writefln("offset %s, size = %s", offset, size);
                try{
                    data.allocRange(offset, size);
                }catch(Exception e) {
                    writefln("FAILED at offset %s, size %s", offset, size);
                    writefln("%s", allocator);
                    //data.dumpRegions();
                    throw e;
                }
                static if(VERBOSE) writefln(" .. Alloced %s bytes at offset %s", size, offset);

            }
            static if(!BENCHMARK) writefln(" (%s alloc regions)", data.alloced.length);
            static if(VERBOSE) writefln("%s", allocator);

            data.check(allocator);

            // Shuffle the list of allocated regions
            Regn[] tempRegns = data.alloced.randomShuffle(rng).dup;

            static if(VERBOSE) data.dumpRegions();

            // Free ~90% of the regions
            static if(!BENCHMARK) writef("  Freeing randomly......");
            uint numToFree = (tempRegns.length*0.9).as!uint;
            static if(VERBOSE) writefln("Freeing %s regions", numToFree);
            foreach(i, a; tempRegns[0..numToFree]) {
                static if(VERBOSE) writefln(" .. Freeing %s bytes at offset %s", a.size, a.offset);
                allocator.free(a.offset, a.size);
                data.free(a.offset, a.size);
            }
            static if(!BENCHMARK) writefln(" (%s alloc regions)", data.alloced.length);

            data.check(allocator);
            static if(!BENCHMARK) writefln("  Check passed");    

            static if(VERBOSE) writefln("%s", allocator);
        }
    }
    static if(!BENCHMARK) writefln("%s", allocator);

    watch.stop();
    writefln("Size %s, took %s millis", SIZE, watch.peek().total!"nsecs"/1_000_000.0);
}

