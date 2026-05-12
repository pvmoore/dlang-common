module _tests.bench.bench_map;

import common;
import common.containers;
import common.containers.containers_internal;
import _tests.bench.bench;

void benchMap() {
    writefln("================================================================");
    writefln(" Benchmarking Maps");
    writefln("================================================================");

    enum numKeys = 10_000;

    executeBenchmarks(getBenchmarks!uint(numKeys));
    executeBenchmarks(getBenchmarks!ulong(numKeys));
    executeBenchmarks(getBenchmarks!float(numKeys));
    executeBenchmarks(getBenchmarks!string(numKeys));
    executeBenchmarks(getBenchmarks!Struct4(numKeys));
    executeBenchmarks(getBenchmarks!Struct8(numKeys));
    executeBenchmarks(getBenchmarks!Struct20(numKeys));
    executeBenchmarks(getBenchmarks!StructToHash(numKeys)); 
}

private:

struct Struct4 { static assert(Struct4.sizeof == 4);
    uint a;
}
struct Struct8 { static assert(Struct8.sizeof == 8);
    uint a;
    uint b;
}
struct Struct20 { static assert(Struct20.sizeof == 20);
    uint a;
    uint b;
    uint c;
    uint d;
    uint e;
}
struct StructToHash {
    uint a;
    uint b;
    uint c;
    uint d;
    uint e;
    ulong toHash() { 
        return djb2_hash(&this, StructToHash.sizeof);
    }
}

Benchmark!T[] getBenchmarks(T)(ulong numKeys) {
    return [
        Benchmark!T("Insert unique",    new InsertKeys!T(createUniqueKeys!T(numKeys))),
        Benchmark!T("Insert duplicate", new InsertKeys!T(createDuplicateKeys!T(numKeys))),
        Benchmark!T("Remove unique",    new RemoveKeys!T(createUniqueKeys!T(numKeys))),
        Benchmark!T("Remove duplicate", new RemoveKeys!T(createDuplicateKeys!T(numKeys))),
        Benchmark!T("Find unique",      new FindKeys!T(createUniqueKeys!T(numKeys))),
        Benchmark!T("Find duplicate",   new FindKeys!T(createDuplicateKeys!T(numKeys))),
    ];
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
interface MapSubject(T) : BenchmarkSubject!T {
    string name();

    void insert(T key, uint value);
    bool remove(T key);
    uint* find(T key);
    ulong size();
    void reset();
}
final class BuiltinMap(T) : MapSubject!T {
    uint[T] map;

    string name() {
        return "BuiltinMap";
    }
    void insert(T key, uint value) {
        map[key] = value;
    }
    bool remove(T key) {
        return map.remove(key);
    }
    uint* find(T key) {
        return key in map;
    }
    ulong size() {
        return map.length;
    }
    void reset() {
        map = null;
    }
}
final class UnorderedMapWrapper(T) : MapSubject!T {
    ulong capacity;
    float loadFactor;
    UnorderedMap!(T, uint) map;

    this(ulong capacity, float loadFactor) {
        this.capacity = capacity;
        this.loadFactor = loadFactor;
        reset();
    }

    string name() {
        return "UnorderedMap (%s, %.2f)".format(capacity, loadFactor);
    }
    void insert(T key, uint value) {
        map.insert(key, value);
    }
    bool remove(T key) {
        return map.remove(key);
    }
    uint* find(T key) {
        return map.getPtr(key);
    }
    ulong size() {
        return map.size();
    }
    void reset() {
        map = new UnorderedMap!(T, uint)(capacity, loadFactor);
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
abstract class MapTask(T) : BenchmarkTask!T {
public:
    this(T[] keys) {
        this.keys = keys;
    }
    override void prepare(BenchmarkSubject!T subject) {
        this.map = subject.as!(MapSubject!T);
        map.reset();
    }
    final void insertKeys() {
        foreach(key; keys) {
            map.insert(key, 1);
        }
    }
    final BenchmarkSubject!T[] getSubjects() {
        return [
            cast(BenchmarkSubject!T)new BuiltinMap!T(),
            
            new UnorderedMapWrapper!(T)(16, 0.75),
            new UnorderedMapWrapper!(T)(16, 0.25),
            new UnorderedMapWrapper!(T)(16, 0.5),
            new UnorderedMapWrapper!(T)(16, 0.8),
            new UnorderedMapWrapper!(T)(16, 0.9),
            new UnorderedMapWrapper!(T)(1024, 0.75),  
        ];
    }
    final string getFinalResult() {
        return "%s".format(count);
    }
protected:
    MapSubject!T map;
    T[] keys;   
    ulong count;
}
final class InsertKeys(T) : MapTask!T {
    this(T[] keys) {
        super(keys);
    }
    override void prepare(BenchmarkSubject!T subject) {
        super.prepare(subject);
    }
    override void execute() {
        foreach(key; keys) {
            map.insert(key, 1);
            count++;
        }
    }
}
final class RemoveKeys(T) : MapTask!T {
    this(T[] keys) {
        super(keys);
    }
    override void prepare(BenchmarkSubject!T subject) {
        super.prepare(subject);
        insertKeys();
    }
    override void execute() {
        foreach(key; keys) {
            count += map.remove(key) ? 1 : 0;
        }
    }
}
final class FindKeys(T) : MapTask!T {
    this(T[] keys) {
        super(keys);
    }
    override void prepare(BenchmarkSubject!T subject) {
        super.prepare(subject);
        insertKeys();
    }
    override void execute() {
        foreach(key; keys) {
            count += map.find(key) !is null ? 1 : 0;
        }
    }
}
