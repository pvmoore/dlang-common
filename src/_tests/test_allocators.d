module _tests.test_allocators;

import std.stdio;
import std.random   : uniform, Mt19937, unpredictableSeed, randomShuffle;
import std.typecons : tuple, Tuple;

import common;
import common.allocators;

void testAllocators() {
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
        expect(fr[0][0]==0 && fr[0][1]==100, "freeRegions = %s".format(fr));
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
