module _tests.containers.test_set;

import common;
import common.containers;
import _tests.test;

void testSet() {
    writefln("-----------------------------------------");
    writefln(" Testing Set");
    writefln("-----------------------------------------");

    {
        writefln(" Empty Set");
        auto s = new Set!int;
        assert(s.isEmpty());
        assert(s.size()==0);
        assert(s.capacity()==16);
    }
    {
        writefln(" Empty Set with capacity");
        auto s = new Set!int(32);
        assert(s.isEmpty());
        assert(s.size()==0);
        assert(s.capacity()==32);
    }
    {
        writefln(" add()");
        auto s = new Set!int(4, 0.75);
        s.add(1);
        assert(!s.isEmpty());
        assert(s.size()==1);
        assert(s.capacity()==4);

        s.add(2);
        assert(s.size()==2);
        assert(s.capacity()==4);

        // This pushes the load above the threshold
        s.add(6);
        assert(s.size()==3);
        assert(s.capacity()==8);
    }
    {
        writefln(" add([])");
        auto s = new Set!int;
        s.add([1, 2, 3]);
        assert(!s.isEmpty());
        assert(s.size()==3);
        assert(s.contains(1));
        assert(s.contains(2));
        assert(s.contains(3));
    }
    {
        writefln(" add(Set)");
        auto s = new Set!int;
        auto s2 = new Set!int;
        s2.add([1, 2, 3]);

        s.add(s2);
        assert(!s.isEmpty());
        assert(s.size()==3);
        assert(s.contains(1));
        assert(s.contains(2));
        assert(s.contains(3));

        // Add null set
        Set!int s3 = null;
        s.add(s3);
        assert(!s.isEmpty());
        assert(s.size()==3);
    }
    {
        writefln(" opIndex()");
        auto s = new Set!int;
        s.add(10);
        s.add(20);
        assert(s[10]);
        assert(s[20]);
        assert(!s[30]);
    }
    {
        writefln(" opIndexAssign()");
        auto s = new Set!int;
        s[10] = true;
        s[20] = true;
        s[50] = true;
        assert(s[10]);
        assert(s[20]);
        assert(s[50]);
        assert(!s[30]);
        assert(s.size()==3);

        // Set to false removes an element if it is in the map
        s[5] = false;
        assert(s.size()==3);
        assert(!s[5]);

        s[20] = false;
        assert(s.size()==2);
        assert(!s[20]);
    }
    {
        writefln(" contains()");
        auto s = new Set!int;
        s.add(10);
        s.add(20);
        assert(s.contains(10));
        assert(s.contains(20));
        assert(!s.contains(30));
    }
    {
        writefln(" remove()");
        auto s = new Set!int;
        s.add(100);
        s.add(200);
        s.add(50);
        s.add(1000);
        assert(s.size()==4);

        // Remove an element that is not in the set
        assert(false == s.remove(10));

        // Remoeve an element that is in the set
        assert(true == s.remove(100));
        assert(s.size()==3);

        // Remove the first element
        assert(true == s.remove(50));
        assert(s.size()==2);

        // Remove the last element
        assert(true == s.remove(1000));
        assert(s.size()==1);
    }
    {
        writefln(" clear()");
        auto s = new Set!int;
        s.add(100);
        s.add(200);
        s.add(50);
        s.add(1000);
        assert(s.size()==4);

        s.clear();
        assert(s.isEmpty());
        assert(s.size()==0);
    }
    {
        writefln(" keys()");
        auto s = new Set!int;
        s.add(100);
        s.add(200);
        s.add(50);
        s.add(1000);
        assert(s.size()==4);

        auto keys = s.keys().sort().array;
        assert(keys == [50, 100, 200, 1000]);
    }
    {
        writefln(" byKey()");
        auto s = new Set!int;
        s.add(100);
        s.add(200);
        s.add(50);
        s.add(1000);
        assert(s.size()==4);

        foreach(k; s.byKey())
            writefln("key = %d", k);
    }
    {
        writefln(" compute()");
        auto s = new Set!int;
        s.add(100);
        s.add(200);
        s.add(50);
        s.add(1000);
        assert(s.size()==4);

        // Compute a key that is in the set. return true to keep the value
        assert(true == s.compute(100, (k) { assert(false); return false; }, (k) { return true; }));
        assert(s.size()==4);
        assert(s.contains(100));

        // Compute a key that is in the set. return false to remove the value
        assert(false == s.compute(100, (k) { assert(false); return false; }, (k) { return false; }));
        assert(s.size()==3);
        assert(!s.contains(100));

        // Compute a key that is not in the set. return true to add the value
        assert(true == s.compute(99, (k) { return true; }, (k) { assert(false); return false; }));
        assert(s.size()==4);
        assert(s.contains(99));

        // Compute a key that is not in the set. return false to not add the value
        assert(false == s.compute(88, (k) { return false; }, (k) { assert(false); return false; }));
        assert(s.size()==4);
        assert(!s.contains(88));
    }

    foreach(i; 0..100) {
        fuzzTestSet(1000);
    }
    writefln("Fuzz testing completed: OK");
}

void fuzzTestSet(uint iterations) {
    Mt19937 rng;
    auto seed = unpredictableSeed();
    rng.seed(seed);

    writefln("Fuzz testing Set for %s iterations, seed = %s", iterations, seed);
    auto s = new Set!int;
    ulong numAdds;
    ulong numRemoves;
    bool[int] keysMap;
    int[] keysList;

    foreach(i; 0..iterations) {
        auto r = uniform01(rng);

        if (r < 0.7) {
            int key = uniform(0.as!int, int.max, rng);
            s[key] = true;

            keysList ~= key;
            keysMap[key] = true;
            numAdds++;
        } else {
            if(keysList.length > 0) {
                uint k = uniform(0.as!uint, keysList.length.as!uint, rng);
                int key = keysList[k];
                s.remove(key);

                keysList.removeAt(k);
                keysMap.remove(key);
                numRemoves++;
            }
        }

        assert(s.size() == keysList.length);
        foreach(k; s.byKey()) {
            assert(keysMap[k]);
        }      
        foreach(k; keysList) {
            assert(s[k]);
        }
    }
    writefln("  Size = %s, Added %s, removed %s", s.size(), numAdds, numRemoves);
}
