module _tests.containers.test_sparse_array;

import common;
import common.containers;
import _tests.test;

void testSparseArray() {
    writefln("----------------------------------------------------------------");
    writefln(" Testing SparseArray");
    writefln("----------------------------------------------------------------");

    {
        auto s = new SparseArray();
     
        // capacity = 64, layers = 0
        s.add(10);
        assert(s.numItems() == 1);
        assert(s.capacity() == 64);
        s.dump();
        assert(s.sparseIndexOf(10) == 0);
        assert(s.sparseIndexOf(11) == 1);

        // capacity = 128, layers = 1
        s.add(65);
        s.add(100);
        assert(s.numItems() == 3);
        assert(s.capacity() == 128);
        s.dump();
        assert(s.sparseIndexOf(65) == 1);
        assert(s.sparseIndexOf(66) == 2);
        assert(s.sparseIndexOf(100) == 2);
        assert(s.sparseIndexOf(101) == 3);

        // capacity = 256, layers = 2
        s.add(130);
        s.add(150);
        assert(s.numItems() == 5);
        assert(s.capacity() == 256);
        s.dump();
        assert(s.sparseIndexOf(130) == 3);
        assert(s.sparseIndexOf(131) == 4);
        assert(s.sparseIndexOf(150) == 4);
        assert(s.sparseIndexOf(151) == 5);

        // s.remove(100);
        // assert(s.numItems() == 4);
        // s.dump();

        // capacity = 512, layers = 3
        s.add(500);
        assert(s.numItems() == 6);
        assert(s.capacity() == 512);
        s.dump();
        assert(s.sparseIndexOf(500) == 5);
        assert(s.sparseIndexOf(501) == 6);

        // capacity = 1024, layers = 4
        s.add(1000);
        assert(s.numItems() == 7);
        assert(s.capacity() == 1024);
        s.dump();
        assert(s.sparseIndexOf(1000) == 6);
        assert(s.sparseIndexOf(1001) == 7);

        // capacity = 2048, layers = 5
        s.add(2000);
        assert(s.numItems() == 8);
        assert(s.capacity() == 2048);
        s.dump();
        assert(s.sparseIndexOf(2000) == 7);
        assert(s.sparseIndexOf(2001) == 8);

        // capacity = 4096, layers = 6
        s.add(4000);
        assert(s.numItems() == 9);
        assert(s.capacity() == 4096);
        s.dump();
        assert(s.sparseIndexOf(4000) == 8);
        assert(s.sparseIndexOf(4001) == 9);

        // capacity = 8192, layers = 7
        s.add(8000);
        assert(s.numItems() == 10);
        assert(s.capacity() == 8192);
        s.dump();
        assert(s.sparseIndexOf(8000) == 9);
        assert(s.sparseIndexOf(8001) == 10);

        // capacity = 16384, layers = 8
        s.add(16000);
        assert(s.numItems() == 11);
        assert(s.capacity() == 16384);
        s.dump();
        assert(s.sparseIndexOf(16000) == 10);
        assert(s.sparseIndexOf(16001) == 11);

        // capacity = 32768, layers = 9
        s.add(32000);
        assert(s.numItems() == 12);
        assert(s.capacity() == 32768);
        s.dump();
        assert(s.sparseIndexOf(32000) == 11);
        assert(s.sparseIndexOf(32001) == 12);

        // capacity = 65536, layers = 10
        s.add(65000);
        assert(s.numItems() == 13);
        assert(s.capacity() == 65536);
        s.dump();
        assert(s.sparseIndexOf(65000) == 12);
        assert(s.sparseIndexOf(65001) == 13);

        // capacity = 131072, layers = 11
        s.add(130000);
        assert(s.numItems() == 14);
        assert(s.capacity() == 131072);
        s.dump();
        assert(s.sparseIndexOf(130000) == 13);
        assert(s.sparseIndexOf(130001) == 14);

        s.remove(10);
        assert(s.numItems() == 13);
        assert(s.capacity() == 131072);
        s.dump();


        //if(1f < 2f) return;
    }
    //──────────────────────────────────────────────────────────────────────────────────────────────────

    {
        writefln(" Default Initialisation");
        auto s = new SparseArray();
        assert(s.isEmpty());
        assert(s.numItems() == 0);
        assert(s.capacity() == 0);
        s.dump();
    }
    {
        writefln(" Initialisation with capacity");
        auto s = new SparseArray(128);
        assert(s.isEmpty());
        assert(s.numItems() == 0);
        assert(s.capacity() == 128);
        s.dump();
    }
    {
        writefln(" add()");
        auto s = new SparseArray();
        s.add(10);
        s.add(60);
        s.add(63);

        s.dump();
        assert(s.sparseIndexOf(10) == 0);
        assert(s.sparseIndexOf(60) == 1);
        assert(s.sparseIndexOf(63) == 2);
        assert(s.sparseIndexOf(64) == 3);
    }
    {
        writefln(" expand()");
        auto s = new SparseArray();

        s.add(6);
        s.add(20);
        s.add(50);
        s.add(32);
        assert(!s.isEmpty());
        assert(s.numItems() == 4);
        assert(s.capacity() == 64);
        assert(s.sparseIndexOf(6) == 0);
        assert(s.sparseIndexOf(20) == 1);
        assert(s.sparseIndexOf(32) == 2);
        assert(s.sparseIndexOf(50) == 3);
        assert(s.sparseIndexOf(60) == 4);
        s.dump();

        // this will expand the tree to capacity 128
        s.add(64);
        s.dump();
        assert(s.numItems() == 5);
        assert(s.capacity() == 128);
        assert(s.sparseIndexOf(64) == 4); 
        assert(s.sparseIndexOf(65) == 5);

        // this will expand the tree to capacity 256
        s.add(128);
        assert(s.numItems() == 6);
        assert(s.capacity() == 256);
        s.dump();

        // this will expand the tree to capacity 512
        s.add(500);
        assert(s.numItems() == 7);
        assert(s.capacity() == 512);
        s.dump();
    }
    {
        writefln(" remove()");

        // Small array without counts
        auto s = new SparseArray();
        s.add(10);
        s.add(60);
        s.add(63);
        assert(s.numItems() == 3);
        assert(s.capacity() == 64);
        assert(s.sparseIndexOf(10) == 0);
        assert(s.sparseIndexOf(11) == 1);
        assert(s.sparseIndexOf(60) == 1);
        assert(s.sparseIndexOf(61) == 2);
        assert(s.sparseIndexOf(63) == 2);
        assert(s.sparseIndexOf(64) == 3);

        assert(s.remove(60));
        assert(s.numItems() == 2);
        assert(s.capacity() == 64);
        assert(s.sparseIndexOf(10) == 0);
        assert(s.sparseIndexOf(11) == 1);
        assert(s.sparseIndexOf(60) == 1);
        assert(s.sparseIndexOf(61) == 1);
        assert(s.sparseIndexOf(63) == 1);
        assert(s.sparseIndexOf(64) == 2);
        s.dump();

        // Array with counts
        s = new SparseArray();
        assert(s.isEmpty());
        assert(s.numItems() == 0);
        assert(s.capacity() == 0);

        // Increase capacity to 128
        s.add(64);
        assert(s.numItems() == 1);
        assert(s.capacity() == 128);
        s.dump();

        assert(!s.remove(20));   // not found
        assert(!s.remove(6000));   // not found
        assert(s.remove(64));
        assert(s.isEmpty());
        assert(s.numItems() == 0);
        assert(s.capacity() == 128);
        s.dump();

        // Increase capacity to 256
        s.add(220);
        assert(s.numItems() == 1);
        assert(s.capacity() == 256);
        s.dump();

        assert(!s.remove(10));   // not found
        assert(s.remove(220));

        assert(s.isEmpty());
        assert(s.numItems() == 0);
        assert(s.capacity() == 256);
        s.dump();
    }   
    {
        writefln(" clear()");
        auto s = new SparseArray();
        s.add(10);
        s.add(60);
        s.add(63);
        s.clear();
        assert(s.isEmpty());
        assert(s.numItems() == 0);
        assert(s.capacity() == 0);
    }
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

            auto s = new SparseArray();

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
                s.add(index);
                if(!array[index]) {
                    array[index] = true;
                    numItems++;
                }
                assert(s.numItems() == numItems);
            }
            void remove(ulong index) {
                //writefln(" - remove(%s)", index);
                bool r = s.remove(index);
                assert(r == array[index]);
                if(array[index]) {
                    array[index] = false;
                    numItems--;
                }
                assert(s.numItems() == numItems);
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
            void checkSparseIndexes() {
                if(capacity < 100_000) {
                    // Check all indexes
                    foreach(i; 0..capacity) {
                        assert(count(i) == s.sparseIndexOf(i), "At index %s - Expected %s but was %s".format(i, count(i), s.sparseIndexOf(i)));
                    }
                } else {
                    // Only check the indexes that we added otherwise we will be here all day
                    assert(count(0) == s.sparseIndexOf(0));
                    foreach(i; 1..capacity) {
                        if(array[i]) {
                            assert(count(i) == s.sparseIndexOf(i), "At index %s - Expected %s but was %s".format(i, count(i), s.sparseIndexOf(i)));
                            assert(count(i-1) == s.sparseIndexOf(i-1), "At index %s - Expected %s but was %s".format(i-1, count(i-1), s.sparseIndexOf(i-1)));
                        }
                    }
                }
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
                    remove(index);

                    // Remove a random index that is in the array
                    if(numItems > 0) {
                        index = selectRandomIndex();
                        remove(index);
                    }
                    numRemoves++;
                }
            }
            checkSparseIndexes();
            assert(s.capacity() <= capacity);
            writefln(" --> adds %s, removes %s", numAdds, numRemoves);
        }

        fuzzTest(20, 65536);
        fuzzTest(1000, 1024);
        foreach(j; 0..100) {
            fuzzTest(10000, 256);
        }
        writefln(" Ok");
    }

    foreach(i; 6..25) {
        ulong capacity = 1 << i;
        auto ss = new SparseArray(capacity);
        assert(ss.capacity() == capacity);
        writefln(" Capacity %s, numBytes = %s", ss.capacity(), ss.numBytesUsed());
    }
}

