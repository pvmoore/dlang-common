module _tests.containers.test_unordered_map;

import common;
import common.containers;
import common.utils;

import _tests.test;

void testUnorderedMap() {
    writefln("----------------------------------------------------------------");
    writefln(" Testing UnorderedMap");
    writefln("----------------------------------------------------------------");

    auto t = new Tester!(MapMaker1);
    t.test();

    // auto t2 = new Tester!(MapMaker2);
    // t2.test();

    writefln("================================================================");
    writefln("Pass");
    writefln("================================================================");
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

struct MapMaker1 {
    static auto newMap(K,V)(ulong capacity, float loadFactor) { 
        return new UnorderedMap!(K,V)(capacity, loadFactor);
    }
}
// struct MapMaker2 {
//     static auto newMap(K,V)(ulong capacity, float loadFactor) { 
//         return new UnorderedMap2!(K,V)(capacity, loadFactor);
//     }
// }

final class Tester(MM) {

    void test() {
        testBasics();
        testDifferentKeyTypes();
        test_insert_get_getPtr();
        testOpIndex();
        testContainsKey();
        testRemove();
        testKeysValues();
        testCompute();
        testClear();
        
        static if(true) {
            foreach(i; 0..5) {
                fuzzTestUnorderedMap(i.as!uint, 10_000);
            }
        }
    }

    void testBasics() {
        writefln("  basics()");
        auto m = MM.newMap!(ulong,ulong)(16, 0.75f);

        assert(m.isEmpty());
        assert(m.size()==0);
        assert(m.capacity()==16);

        // These should not be found
        assert(m.get(7) == 0);
        assert(m.get(0, 7) == 7);

        // Slots | Keys
        // ------|----------------------------------
        // 0     | 0,3,50,69,73,83
        // 1     | 13,18,57
        // 2     | 20,28,29,30,36,42,93
        // 3     | 39,45,64,74
        // 4     | 4,7,48,53,56,67,72
        // 5     | 1,23,31,32,40,41,60,63,68,86
        // 6     | 90,92
        // 7     | 9,19,33,44,52,78,85,89
        // 8     | 8,24,25,37,58,77
        // 9     | 10,14,15,21,51,71,79,84,87,96,97,99
        // 10    | 2,43,80,95
        // 11    | 22,26,46,55,62,65,82
        // 12    | 5,6,12,27,34,47,54,70,81
        // 13    | 11,16,75,76,94
        // 14    | 17,35,38,59
        // 15    | 49,61,66,88,91,98

        // These hash to the same slot [0]
        m.insert(0, 90);         
        m.insert(3, 40);    

        assert(!m.isEmpty());
        assert(m.size()==2);
        assert(m.capacity()==16);
        assert(m.get(0)==90);
        assert(m.get(3)==40);

        // These hash to the same slot [0]
        m.insert(3, 50);
        m.insert(0, 60); 
        assert(m.size()==2);
        assert(m.get(3)==50);
        assert(m.get(0)==60);

        // These hash to the same slot [0]
        m.insert(0, 70); 
        m.insert(3, 80);
        assert(m.size()==2);
        assert(m.get(3)==80);
        assert(m.get(0)==70);

        // These hash to the same slot [16] and will wrap round to start filling from [2]
        m.insert(20, 1);
        m.insert(28, 2);   
        m.insert(29, 3);    
        m.insert(30, 4);   
        assert(m.size()==6);
        assert(m.get(20)==1);
        assert(m.get(28)==2);
        assert(m.get(29)==3);
        assert(m.get(30)==4);
        assert(*m.getPtr(30)==4);

        assert(m.remove(900) == false);
        assert(m.size()==6);

        m.dump();

        assert(m.remove(3));
        assert(m.size()==5);

        //m.put(81, 3);

        m[81] = 3;
        assert(m.size()==6);
        assert(m[81]==3);

        m[81] = 4;
        m[82] = 5;
        m[83] = 6;
        m[84] = 7;
        m[85] = 8;
        m[86] = 9;
        m[87] = 10;
        m[88] = 11;    
        m[89] = 12;
        m[90] = 13;

        // This will cause a resize
        //m[91] = 14;

        m.dump();
    }

    void testDifferentKeyTypes() {
        ulong hash0(ulong x) {
            x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9L;
            x = (x ^ (x >> 27)) * 0x94d049bb133111ebL;
            x = x ^ (x >> 31);
            return x;
        }

        writefln("  Different key types");
        writefln("   - ulong");
        auto ulongMap = new UnorderedMap!(ulong,uint);
        ulongMap.insert(1, 10);

        writefln("   - int");
        auto intMap = new UnorderedMap!(int,uint);
        intMap.insert(1, 10);

        writefln("   - float");
        auto floatMap = new UnorderedMap!(float,uint);
        floatMap.insert(1.0f, 10);
        assert(floatMap.get(1.0f)==10);

        // string
        writefln("   - string");
        auto stringMap = new UnorderedMap!(string,uint);
        stringMap.insert("hello", 10);
        assert(stringMap.get("hello")==10);

        writefln("   - struct with toHash()");
        // struct with toHash method (will use S.toHash and bitwise equality)
        struct S {
            int a;
            int b;
            static bool toHashCalled;

            ulong toHash() { 
                toHashCalled = true;
                return hash0(a.as!ulong << 32 | b); 
            }
        }

        auto structMap = new UnorderedMap!(S,uint);
        structMap.insert(S(1,2), 10);
        assert(structMap.get(S(1,2))==10);
        assert(S.toHashCalled);

        writefln("   - struct without toHash()");
        // struct without toHash method (will use TypeInfo.getHash and S2.opEquals)
        struct S2 {
            int a;
            int b;
            static bool opEqualsCalled;

            // This will be called by the map to test equality (eg. ==)
            // otherwise bitwise equality will be used
            bool opEquals(S2 o) const {
                opEqualsCalled = true;
                return a==o.a && b==o.b; 
            }
        }
        auto structMap2 = new UnorderedMap!(S2,uint);
        structMap2.insert(S2(1,2), 10);
        structMap2.insert(S2(1,2), 20);
        assert(structMap2.get(S2(1,2))==20);
        assert(S2.opEqualsCalled);

        writefln("   - class with toHash() and opEquals()");
        // class (will use C.getHash and C.opEquals)
        class C { 
            int a; 
            int b;
            this(int a, int b) { this.a = a; this.b = b; } 
            static bool toHashCalled;
            static bool opEqualsCalled;

            override ulong toHash() { 
                toHashCalled = true;
                return hash0(a.as!ulong << 32 | b); 
            }
            override bool opEquals(Object o) {
                opEqualsCalled = true;
                C c = cast(C)o;
                return a==c.a && b==c.b; 
            }
        }

        auto classMap = new UnorderedMap!(C,uint);
        classMap.insert(new C(1,2), 10);
        classMap.insert(new C(1,2), 20);
        assert(classMap.get(new C(1,2))==20);
        assert(C.toHashCalled);
        assert(C.opEqualsCalled);
    }

    void test_insert_get_getPtr() {
        writefln("  insert()");
        auto m = new UnorderedMap!(uint,ulong);

        m.insert(19, 80);
        m.insert(11, 60); 
        m.insert(3, 40);      
        m.insert(7, 50);
        m.insert(15, 70); 
        m.insert(0, 90);         
        assert(m.size()==6);

        writefln("  get()");
        assert(m.get(19)==80);
        assert(m.get(11)==60);
        assert(m.get(3)==40);
        assert(m.get(7)==50);
        assert(m.get(15)==70);
        assert(m.get(0)==90);

        writefln("  getPtr()");
        ulong* p = m.getPtr(19);
        assert(p);
        assert(*p == 80);
        ulong* p2 = m.getPtr(19);
        // The value ptrs should be the same
        assert(p == p2);

        assert(*m.getPtr(19)==80);
        assert(*m.getPtr(11)==60);
        assert(*m.getPtr(3)==40);
        assert(*m.getPtr(7)==50);
        assert(*m.getPtr(15)==70);
        assert(*m.getPtr(0)==90);
    }

    void testOpIndex() {
        writefln("  opIndex()");
        auto m = new UnorderedMap!(uint,ulong);
        m.insert(19, 80);
        m.insert(11, 60); 
        m.insert(3, 40);      
        m.insert(7, 50);
        m.insert(15, 70); 
        m.insert(0, 90);         
        assert(m.size()==6);
        assert(m[19]==80);
        assert(m[11]==60);
        assert(m[3]==40);
        assert(m[7]==50);
        assert(m[15]==70);
        assert(m[0]==90);

        // Not found
        assert(m[99] == 0); // uint.init
        assert(m[16] == 0);

        writefln("  opIndexAssign()");
        m[99] = 7;
        m[16] = 8;
        m[99] = 9;
        assert(m.size()==8);
        assert(m[99]==9);
        assert(m[16]==8);
    }

    void testContainsKey() {
        writefln("  containsKey()");
        auto m = new UnorderedMap!(ulong,ulong);
        m.insert(19, 80);
        m.insert(11, 60); 
        m.insert(3, 40);      
        m.insert(7, 50);
        m.insert(15, 70); 
        m.insert(0, 90);         
        assert(m.size()==6);
        assert(m.containsKey(19));
        assert(m.containsKey(11));
        assert(m.containsKey(3));
        assert(m.containsKey(7));
        assert(m.containsKey(15));
        assert(m.containsKey(0));
        assert(!m.containsKey(99));
        assert(!m.containsKey(16));
    }

    void testRemove() {
        writefln("  remove()");
        auto m = new UnorderedMap!(ulong,ulong);
        m.insert(19, 80);
        m.insert(11, 60); 
        m.insert(3, 40);      
        m.insert(7, 50);
        m.insert(15, 70); 
        m.insert(0, 90);         
        assert(m.size()==6);

        assert(!m.remove(99));
        assert(!m.remove(16));

        assert(m.remove(3));
        assert(m.remove(7));
        assert(m.remove(19));
        assert(m.remove(11));
        assert(m.remove(15));
        assert(m.remove(0));
        
        assert(m.size()==0);
    }

    void testKeysValues() {
        writefln(" keys(), values(), byKey(), byValue(), byKeyValue()");
        auto m = new UnorderedMap!(ulong,ulong)(16, 1.0f);
        m.insert(19, 80);
        m.insert(11, 60); 
        m.insert(3, 40);      
        m.insert(7, 50);
        m.insert(15, 70); 
        m.insert(0, 90);         
        assert(m.size()==6);

        ulong[] keys = m.keys();
        keys.sort();
        assert(keys == [0,3,7,11,15,19]);

        // The keys array should be a copy
        ulong[] keys2 = m.keys();
        assert(keys2.ptr != keys.ptr);
        
        ulong[] values = m.values();
        values.sort();
        assert(values == [40,50,60,70,80,90]);

        // The values array should be a copy
        ulong[] values2 = m.values();
        assert(values2.ptr != values.ptr);

        writefln("byKeyValue:");
        foreach(e; m.byKeyValue()) {
            writefln("%s = %s", e.key, e.value);
        }
        writefln("byKey:");
        foreach(e; m.byKey()) {
            writefln("%s", e);
        }
        writefln("byValue:");
        foreach(e; m.byValue()) {
            writefln("%s", e);
        }
        
        m.dump();
    }

    void testCompute() {
        writefln("  compute()");
        auto m = new UnorderedMap!(ulong,ulong)(16, 1.0f);
        m.insert(19, 80);
        assert(m.size()==1);

        // Key is in the map. Call updateFunc and set v = 3 and return true to update the value
        m.compute(19, (k,v) { assert(false); return false;}, (k,v) { *v = 3; return true; });
        assert(m.get(19) == 3);
        assert(m.size()==1);

        // Key is in the map. Call updateFunc and set v = 4 and return false to remove the key
        m.compute(19, (k,v) { assert(false); return false; }, (k,v) { *v = 4; return false; });
        assert(!m.containsKey(19));
        assert(m.size()==0);

        // Key is not in the map. Call insertFunc, set v = 4 and return true to insert the key,value
        m.compute(11, (k,v) { *v = 4; return true; }, (k,v) { assert(false); return false; });
        assert(m.get(11) == 4);
        assert(m.size()==1);

        // Key is not in the map. Call insertFunc, set v = 5 and return false to not insert the key,value
        m.compute(12, (k,v) { *v = 5; return false; }, (k,v) { assert(false); return false; });
        assert(!m.containsKey(12));
        assert(m.size()==1);
    }

    void testClear() {
        writefln("  clear()");
        auto m = new UnorderedMap!(ulong,ulong);
        assert(m.size() == 0);
        assert(m.capacity() == 16);

        m.insert(19, 80);
        m.insert(11, 60); 
        m.insert(3, 40);      
        m.insert(7, 50);
        m.insert(15, 70); 
        m.insert(0, 90);         
        assert(m.size()==6);

        m.clear();
        
        assert(m.size()==0);
        assert(m.capacity() == 16);
    }

    void fuzzTestUnorderedMap(uint iteration, uint numActions) {
        writefln("----------------------------------------------------------------");
        writefln(" [%s] Fuzz Testing UnorderedMap (%s actions)", iteration+1, numActions);
        writefln("----------------------------------------------------------------");

        Mt19937 rng;
        auto seed = unpredictableSeed();
        //seed = 3413898126;
        rng.seed(seed);
        writefln("seed = %s", seed);

        auto um = new UnorderedMap!(ulong,ulong)(16, 0.95);
        ulong[ulong] dmap;

        void dumpMaps() {
            import std.algorithm : sort;
            um.dump();
            writefln("----------------------------------------------------------------");
            writefln("Dumping UnorderedMap (size = %s)", um.size());
            writefln("----------------------------------------------------------------");
            auto sortedKeys = um.keys().sort();
            foreach(k; sortedKeys) {
                writefln("%s = %s", k, um.get(k));
            }
            writefln("----------------------------------------------------------------");
            writefln("Dumping dmap (length = %s)", dmap.length);
            writefln("----------------------------------------------------------------");
            sortedKeys = dmap.keys.sort();
            foreach(k; sortedKeys) {
                writefln("%s = %s", k, dmap[k]);
            }
        }

        ulong[] keys;

        ulong getKey() {
            if(keys.length == 0) return 0;
            if(keys.length == 1) return keys[0];
            return keys[uniform(0, keys.length, rng)];
        }

        ulong numInserts = 0;
        ulong numUpdates = 0;
        ulong numRemoves = 0;

        try{
            foreach(i; 0..numActions) {

                // Collect garbage every 1000 actions to see if any of our values disappear
                if((i % 1000) == 0) {
                    GC.collect();
                }

                auto r = uniform01(rng);

                if(r < 0.7) {
                    // Add a new key
                    ulong key = uniform(0L, 1_000_000_000L, rng);
                    keys ~= key;
                    //writefln("Adding %s = %s", key, i);

                    um.insert(key, i);
                    dmap[key] = i;
                    numInserts++;
                } else if(keys.length > 0 && r < 0.85) {
                    // Update a key
                    ulong key = getKey();
                    //writefln("Updating %s = %s", key, i);

                    um.insert(key, i);
                    dmap[key] = i;
                    numUpdates++;
                } else {
                    // Remove a key
                    ulong key = getKey();
                    //writefln("Removing %s", key);

                    bool a = um.remove(key);
                    bool b = dmap.remove(key);
                    numRemoves++;
                    throwIfNot(a == b, "remove %s failed, a = %s, b = %s", key, a, b);
                }
                // Check size
                throwIfNot(um.size()==dmap.length);
                // Check key, values
                foreach(k; um.keys()) {
                    throwIfNot(um.get(k) == dmap[k]);
                }
                foreach(k; dmap.keys()) {
                    throwIfNot(um.get(k) == dmap[k]);
                }
            }
        }catch(Exception e) {
            writefln("Failed: %s", e);
            dumpMaps();
            throw e;
        }
        writefln(" Passed: %s keys, %s inserts, %s updates, %s removes", um.size(), numInserts, numUpdates, numRemoves);
        //um.dump();
    }
}
