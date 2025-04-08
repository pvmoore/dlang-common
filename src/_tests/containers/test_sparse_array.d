module _tests.containers.test_sparse_array;

import common;
import common.containers;
import _tests.test;

void testSparseArray() {
    writefln("----------------------------------------------------------------");
    writefln(" Testing SparseArray");
    writefln("----------------------------------------------------------------");

    {
        writefln(" Default Initialisation");
        auto s = new SparseArray!uint();
        assert(s.isEmpty());
        assert(s.length() == 0);
        assert(s.capacity() == 0);
        s.dump();
    }
    {
        writefln(" Initialisation with capacity");
        auto s = new SparseArray!uint(128);
        assert(s.isEmpty());
        assert(s.length() == 0);
        assert(s.capacity() == 128);
        s.dump();
    }
    {
        writefln(" opIndexAssign() add");
        auto s = new SparseArray!uint();

        s[10] = 3;

        assert(!s.isEmpty());
        assert(s.length() == 1);
        assert(s.capacity() == 64);
        assert(s.values() == [3]);

        s[50] = 4;
        assert(s.length() == 2);
        assert(s.capacity() == 64);
        assert(s.values() == [3, 4]);
        s.dump();

        s[120] = 5;
        assert(s.length() == 3);
        assert(s.capacity() == 128);
        assert(s.values() == [3, 4, 5]);
        s.dump();

        s[75] = 6;
        assert(s.length() == 4);
        assert(s.capacity() == 128);
        assert(s.values() == [3, 4, 6, 5]);
        s.dump();

        s[0] = 99;
        assert(s.length() == 5);
        assert(s.capacity() == 128);
        assert(s.values() == [99, 3, 4, 6, 5]);
        s.dump();

        s[127] = 70;
        assert(s.length() == 6);
        assert(s.capacity() == 128);
        assert(s.values() == [99, 3, 4, 6, 5, 70]);
        s.dump();
    }
    {
        writefln(" opIndexAssign() replace");
        auto s = new SparseArray!uint();

        s[10] = 3;
        s[10] = 4;
        assert(s.length() == 1);
        assert(s.capacity() == 64);
        assert(s.values() == [4]);
        s.dump();

        s[20] = 5;
        s[30] = 6;
        assert(s.length() == 3);
        assert(s.capacity() == 64);
        assert(s.values() == [4, 5, 6]);
        s.dump();

        s[10] = 7;
        assert(s.length() == 3);
        assert(s.capacity() == 64);
        assert(s.values() == [7, 5, 6]);
        s.dump();

        s[30] = 8;
        assert(s.length() == 3);
        assert(s.capacity() == 64);
        assert(s.values() == [7, 5, 8]);
        s.dump();
    }
    {
        writefln(" clear()");
        // if not initialised with capacity, capacity should be 0 after clear
        auto s = new SparseArray!uint();
        s[50] = 3;
        s[700] = 4;
        s[1000] = 5;
        s.clear();
        assert(s.isEmpty());
        assert(s.length() == 0);
        assert(s.capacity() == 0);

        // if initialised with capacity, capacity should not be reset after clear
        auto s2 = new SparseArray!uint(128);
        s2[50] = 3;
        s2[700] = 4;
        s2[1000] = 5;
        s2.clear();
        assert(s2.isEmpty());
        assert(s2.length() == 0);
        assert(s2.capacity() == 128);
    }
    {
        writefln(" opIndex()");
        auto s = new SparseArray!uint();
        s[50] = 3;
        s[700] = 4;
        s[1000] = 5;
        assert(s.values() == [3, 4, 5]);
        assert(s[50] == 3);
        assert(s[700] == 4);
        assert(s[1000] == 5);
        assert(s[100] == 0); // T.init
    }
    {
        writefln(" removeAt()");
        auto s = new SparseArray!uint();
        s[50] = 3;
        s[700] = 4;
        s[1000] = 5;
        assert(s.values() == [3, 4, 5]);
        assert(s.capacity() == 1024);

        s.removeAt(700);

        assert(s.length() == 2);
        assert(s.capacity() == 1024);
        assert(s.values() == [3, 5]);
        s.dump();
    }
    {
        writefln(" isPresent()");
        auto s = new SparseArray!uint();
        s[50] = 3;
        s[700] = 4;
        assert(s.isPresent(50));
        assert(s.isPresent(700));
        assert(!s.isPresent(1000));
    }
    {
        writefln(" computeIfPresent()");
        auto s = new SparseArray!uint();
        s[50] = 3;
        s[700] = 4;

        // Update index 50 which is present, return true to keep the index in the array
        assert(s.computeIfPresent(50, (ulong u, uint* v) { *v += 10; return true; }) == true);
        assert(s[50] == 13);

        // Update index 700 which is present, return false to remove the index from the array
        assert(s.computeIfPresent(700, (ulong u, uint* v) { *v += 10; return false; }) == false);
        assert(!s.isPresent(700));
        assert(s.length()==1);
        assert(s.values() == [13]);

        // Update index 1000 which is not present
        assert(s.computeIfPresent(1000, (ulong u, uint* v) { assert(false); return true; }) == false);
        assert(!s.isPresent(1000));

        s.dump();

        //if(1f < 2f) return;
    }

    {
        auto s = new SparseArray!uint();
     
        // capacity = 64, layers = 0
        s[10] = 3;
        assert(s.length() == 1);
        assert(s.capacity() == 64);
        s.dump();
        assert(s.values() == [3]);

        // capacity = 128, layers = 1
        s[65] = 4;
        s[100] = 2;
        assert(s.length() == 3);
        assert(s.capacity() == 128);
        s.dump();
        assert(s.values() == [3, 4, 2]);

        // capacity = 256, layers = 2
        s[130] = 1;
        s[150] = 5;
        assert(s.length() == 5);
        assert(s.capacity() == 256);
        s.dump();
        assert(s.values() == [3, 4, 2, 1, 5]);

        // s.removeAt(100);
        // assert(s.numItems() == 4);
        // s.dump();

        // capacity = 512, layers = 3
        s[500] = 7;
        assert(s.length() == 6);
        assert(s.capacity() == 512);
        s.dump();
        assert(s.values() == [3, 4, 2, 1, 5, 7]);

        // capacity = 1024, layers = 4
        s[1000] = 0;
        assert(s.length() == 7);
        assert(s.capacity() == 1024);
        s.dump();
        assert(s.values() == [3, 4, 2, 1, 5, 7, 0]);

        // capacity = 2048, layers = 5
        s[2000] = 11;
        assert(s.length() == 8);
        assert(s.capacity() == 2048);
        s.dump();
        assert(s.values() == [3, 4, 2, 1, 5, 7, 0, 11]);

        // capacity = 4096, layers = 6
        s[4000] = 90;
        assert(s.length() == 9);
        assert(s.capacity() == 4096);
        s.dump();
        assert(s.values() == [3, 4, 2, 1, 5, 7, 0, 11, 90]);

        // capacity = 8192, layers = 7
        s[8000] = 15;
        assert(s.length() == 10);
        assert(s.capacity() == 8192);
        s.dump();
        assert(s.values() == [3, 4, 2, 1, 5, 7, 0, 11, 90, 15]);

        // capacity = 16384, layers = 8
        s[16000] = 100;
        assert(s.length() == 11);
        assert(s.capacity() == 16384);
        s.dump();
        assert(s.values() == [3, 4, 2, 1, 5, 7, 0, 11, 90, 15, 100]);

        // capacity = 32768, layers = 9
        s[32000] = 19;
        assert(s.length() == 12);
        assert(s.capacity() == 32768);
        s.dump();
        assert(s.values() == [3, 4, 2, 1, 5, 7, 0, 11, 90, 15, 100, 19]);

        // capacity = 65536, layers = 10
        s[65000] = 88;
        assert(s.length() == 13);
        assert(s.capacity() == 65536);
        s.dump();
        assert(s.values() == [3, 4, 2, 1, 5, 7, 0, 11, 90, 15, 100, 19, 88]);

        // capacity = 131072, layers = 11
        s[130000] = 55;
        assert(s.length() == 14);
        assert(s.capacity() == 131072);
        s.dump();
        assert(s.values() == [3, 4, 2, 1, 5, 7, 0, 11, 90, 15, 100, 19, 88, 55]);

        s.removeAt(10);
        assert(s.length() == 13);
        assert(s.capacity() == 131072);
        s.dump();
        assert(s.values() == [4, 2, 1, 5, 7, 0, 11, 90, 15, 100, 19, 88, 55]);
    }
    {
        writefln(" opApply() opIndexApply");
        auto s = new SparseArray!uint();
        s[10] = 3;
        s[65] = 4;
        s[100] = 2;
        s[130] = 1;
        s[150] = 5;

        foreach(v; s) {
            writefln(" %s",  v);
        }
        foreach(i, v; s) {
            writefln("[%s] %s", i, v);
        }
    }
    {
        writefln(" range()");
        auto s = new SparseArray!uint();
        s[10] = 3;
        s[65] = 4;
        s[100] = 2;
        s[130] = 1;
        s[150] = 5;

        import std.range.primitives;

        alias R = typeof(s.range());

        assert(isRandomAccessRange!R);

        writefln(" isInputRange = %s", isInputRange!R);
        writefln(" isForwardRange = %s", isForwardRange!R);
        writefln(" isBidirectionalRange = %s", isBidirectionalRange!R);
        writefln(" isRandomAccessRange = %s", isRandomAccessRange!R);
        writefln(" hasSwappableElements = %s", hasSwappableElements!R); 
        writefln(" hasAssignableElements = %s", hasAssignableElements!R);

        //if(1f < 2f) return;
    }
    
    //──────────────────────────────────────────────────────────────────────────────────────────────────

    {
        writefln("----------------------------------------------------------------");
        writefln(" fuzz test");
        writefln("----------------------------------------------------------------");
        void fuzzTest(uint iterations, uint capacity) {

            Mt19937 rng;
            auto seed = unpredictableSeed();
            writef("iterations: %s, capacity: %s, seed: %s", iterations, capacity, seed);
            rng.seed(seed);

            bool[] array = new bool[capacity];
            uint numItems = 0;
            uint numAdds;
            uint numRemoves;

            auto s = new SparseArray!bool();

            ulong count(uint index) {
                if(index == 0) return 0;
                ulong c = 0;
                foreach(i; 0..index) {
                    if(array[i]) c++;
                }
                return c;
            }
            void add(ulong index) {
                //writefln(" - add(%s)", index);

                s[index] = true;

                if(!array[index]) {
                    array[index] = true;
                    numItems++;
                }
                assert(s.length() == numItems);
            }
            void removeAt(ulong index) {
                //writefln(" - removeAt(%s)", index);

                bool r = s.removeAt(index);

                assert(r == array[index]);
                if(array[index]) {
                    array[index] = false;
                    numItems--;
                }
                assert(s.length() == numItems);
            }
            ulong selectRandomIndex() {
                assert(numItems > 0);
                long r = uniform(0, numItems, rng);
                foreach(i; 0..capacity) {
                    if(array[i]) {
                        r--;
                        if(r <= 0) return i;
                    }
                }
                assert(false);
            }
            void checkValues() {
                foreach(i; 0..capacity) {
                    assert(s[i] == array[i]);
                }
                // if(capacity < 100_000) {
                //     // Check all indexes
                //     foreach(i; 0..capacity) {
                //         assert(count(i) == s.sparseIndexOf(i), "At index %s - Expected %s but was %s".format(i, count(i), s.sparseIndexOf(i)));
                //     }
                // } else {
                //     // Only check the indexes that we added otherwise we will be here all day
                //     assert(count(0) == s.sparseIndexOf(0));
                //     foreach(i; 1..capacity) {
                //         if(array[i]) {
                //             assert(count(i) == s.sparseIndexOf(i), "At index %s - Expected %s but was %s".format(i, count(i), s.sparseIndexOf(i)));
                //             assert(count(i-1) == s.sparseIndexOf(i-1), "At index %s - Expected %s but was %s".format(i-1, count(i-1), s.sparseIndexOf(i-1)));
                //         }
                //     }
                // }
            }

            foreach(i; 0..iterations) {
                auto r = uniform01(rng);

                if(r < 0.6) {
                    // Add an index in a random location
                    ulong index = uniform(0, capacity, rng);
                    assert(index < capacity);
                    add(index);
                    numAdds++;

                } else {
                    // Remove a purely random index
                    ulong index = uniform(0, capacity, rng);
                    assert(index < capacity);
                    removeAt(index);

                    // Remove a random index that is in the array
                    if(numItems > 0) {
                        index = selectRandomIndex();
                        removeAt(index);
                    }
                    numRemoves++;
                }
            }
            checkValues();
            assert(s.capacity() <= capacity);
            writefln(" --> adds %s, removes %s", numAdds, numRemoves);
        }

        fuzzTest(10, 1024);

        fuzzTest(200, 1024*1024*64);
        fuzzTest(500, 1024*1024*16);
        fuzzTest(20, 65536);
        fuzzTest(1000, 1024);
        foreach(j; 0..100) {
            fuzzTest(10000, 256);
        }
        writefln(" Ok");
    }

    foreach(i; 6..25) {
        ulong capacity = 1 << i;
        auto ss = new SparseArray!uint(capacity);
        assert(ss.capacity() == capacity);
        writefln(" Capacity %s, numBytes = %s", ss.capacity(), ss.numBytesUsed());
    }
}

