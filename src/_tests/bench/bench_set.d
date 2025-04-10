module _tests.bench.bench_set;

import common;
import common.containers;
import _tests.bench.bench;

void benchSet() {
    writefln("================================================================");
    writefln(" Benchmarking Sets");
    writefln("================================================================");

    enum numKeys = 10_000;

    executeBenchmarks(getBenchmarks!uint(numKeys));

}

private:

Benchmark!T[] getBenchmarks(T)(ulong numKeys) {
    return [
        Benchmark!T("Insert unique",    new InsertKeys!T(createUniqueKeys!T(numKeys))),
        Benchmark!T("Insert duplicate", new InsertKeys!T(createDuplicateKeys!T(numKeys))),
        Benchmark!T("Remove unique",    new RemoveKeys!T(createUniqueKeys!T(numKeys))),
        Benchmark!T("Remove duplicate", new RemoveKeys!T(createDuplicateKeys!T(numKeys))),
        Benchmark!T("Contains unique",    new ContainsKeys!T(createUniqueKeys!T(numKeys))),
        Benchmark!T("Contains duplicate", new ContainsKeys!T(createDuplicateKeys!T(numKeys))),
    ];
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
interface SetSubject(T) : BenchmarkSubject!T {
    string name();

    void add(T key);
    bool remove(T key);
    bool contains(T key);
    ulong size();
    void reset();
}
final class BuiltinSet(T) : SetSubject!T {
    bool[T] map;

    string name() {
        return "BuiltinSet ......";
    }
    void add(T key) {
        map[key] = true;
    }
    bool remove(T key) {
        return map.remove(key);
    }
    bool contains(T key) {
        return (key in map) !is null;
    }
    ulong size() {
        return map.length;
    }
    void reset() {
        map = null;
    }
}
final class SetWrapper(T) : SetSubject!T {
    ulong capacity;
    float loadFactor;
    Set!(T) set;

    this(ulong capacity, float loadFactor) {
        this.capacity = capacity;
        this.loadFactor = loadFactor;
        reset();
    }

    string name() {
        return "Set(%s, %.2f) ...".format(capacity, loadFactor);
    }
    void add(T key) {
        set.add(key);
    }
    bool remove(T key) {
        return set.remove(key);
    }
    bool contains(T key) {
        return set.contains(key);
    }
    ulong size() {
        return set.size();
    }
    void reset() {
        set = new Set!T(capacity, loadFactor);
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
abstract class SetTask(T) : BenchmarkTask!T {
public:
    this(T[] keys) {
        this.keys = keys;
    }
    override void prepare(BenchmarkSubject!T subject) {
        this.set = subject.as!(SetSubject!T);
        set.reset();
    }
    final void insertKeys() {
        foreach(key; keys) {
            set.add(key);
        }
    }
    final BenchmarkSubject!T[] getSubjects() {
        return [
            cast(BenchmarkSubject!T)new BuiltinSet!T(),
            new SetWrapper!T(16, 0.75),
            new SetWrapper!T(16, 0.5),
            new SetWrapper!T(16, 0.25),
            // new UnorderedMapWrapper!(T, 0)(16, 0.9),
            // new UnorderedMapWrapper!(T, 3)(16, 0.9), 
            // new UnorderedMapWrapper!(T, 0)(16, 0.8),
            // new UnorderedMapWrapper!(T, 3)(16, 0.8),
            // new UnorderedMapWrapper!(T, 0)(16, 0.75),
            // new UnorderedMapWrapper!(T, 3)(16, 0.75),
            // new UnorderedMapWrapper!(T, 3)(1024, 0.75),  
            // new UnorderedMapWrapper!(T, 0)(16, 0.6),
            // new UnorderedMapWrapper!(T, 3)(16, 0.6),
            // new UnorderedMapWrapper!(T, 0)(16, 0.5),
            // new UnorderedMapWrapper!(T, 3)(16, 0.5),
            // new UnorderedMapWrapper!(T, 3)(16, 0.25),
        ];
    }
    final string getFinalResult() {
        return "%s".format(count);
    }
protected:
    SetSubject!T set;
    T[] keys;  
    ulong count; 
}
final class InsertKeys(T) : SetTask!T {
    this(T[] keys) {
        super(keys);
    }
    override void prepare(BenchmarkSubject!T subject) {
        super.prepare(subject);
    }
    override void execute() {
        foreach(key; keys) {
            set.add(key);
        }
    }
}
final class RemoveKeys(T) : SetTask!T {
    this(T[] keys) {
        super(keys);
    }
    override void prepare(BenchmarkSubject!T subject) {
        super.prepare(subject);
        insertKeys();
    }
    override void execute() {
        foreach(key; keys) {
            count += set.remove(key) ? 1 : 0;
        }
    }
}
final class ContainsKeys(T) : SetTask!T {
    this(T[] keys) {
        super(keys);
    }
    override void prepare(BenchmarkSubject!T subject) {
        super.prepare(subject);
        insertKeys();
    }
    override void execute() {
        foreach(key; keys) {
            count += set.contains(key);
        }
    }
}
