module _tests.bench.bench_map;

import common;
import _tests.bench.bench;

void benchMap() {
    writefln("================================================================");
    writefln(" Benchmarking Maps");
    writefln("================================================================");

    run(10_000);
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

auto getMaps(T)() {
    return [
        cast(Map!T)new BuiltinMap!T(),
        new UnorderedMapWrapper!(T, 0)(16, 0.9),
        new UnorderedMapWrapper!(T, 3)(16, 0.9), 
        new UnorderedMapWrapper!(T, 0)(16, 0.8),
        new UnorderedMapWrapper!(T, 3)(16, 0.8),
        new UnorderedMapWrapper!(T, 0)(16, 0.75),
        new UnorderedMapWrapper!(T, 3)(16, 0.75),
        new UnorderedMapWrapper!(T, 3)(1024, 0.75),  
        new UnorderedMapWrapper!(T, 0)(16, 0.6),
        new UnorderedMapWrapper!(T, 3)(16, 0.6),
        new UnorderedMapWrapper!(T, 0)(16, 0.5),
        new UnorderedMapWrapper!(T, 3)(16, 0.5),
        new UnorderedMapWrapper!(T, 3)(16, 0.25),
    ];
}
auto getBenchmarks(T)(ulong numKeys) {
    return [
        Benchmark!T("Insert unique",    new InsertKeys!T, createUniqueKeys!T(numKeys)),
        Benchmark!T("Insert duplicate", new InsertKeys!T, createDuplicateKeys!T(numKeys)),
        Benchmark!T("Remove unique",    new RemoveKeys!T, createUniqueKeys!T(numKeys)),
        Benchmark!T("Remove duplicate", new RemoveKeys!T, createDuplicateKeys!T(numKeys)),
        Benchmark!T("Find unique",      new FindKeys!T,   createUniqueKeys!T(numKeys)),
        Benchmark!T("Find duplicate",   new FindKeys!T,   createDuplicateKeys!T(numKeys)),
    ];
}
auto createUniqueKeys(T : uint)(ulong num) {
    T[] keys = new T[num];
    foreach(i; 0..num) {
        keys[i] = uniform(0, uint.max);
    }
    randomShuffle(keys);
    return keys;
}
auto createUniqueKeys(T : string)(ulong num) {
    T[] keys = new T[num];
    foreach(i; 0..num) {
        keys[i] = uniform(0, uint.max).to!string;
    }
    randomShuffle(keys);
    return keys;
}
auto createDuplicateKeys(T : uint)(ulong num) {
    T[] keys = new T[num];
    foreach(i; 0..num) {
        keys[i] = uniform(0, 100);
    }
    randomShuffle(keys);
    return keys;
}
auto createDuplicateKeys(T : string)(ulong num) {
    T[] keys = new T[num];
    foreach(i; 0..num) {
        keys[i] = uniform(0, 100).to!string;
    }
    randomShuffle(keys);
    return keys;
}

struct Benchmark(T) {
    string label;
    Task!T task;
    T[] keys;
}
struct Result {
    string name;
    ulong average;
    ulong[] elapsed;

    void calculateAverage() {
        ulong minIndex = ulong.max;
        ulong maxIndex = ulong.max;
        ulong count = elapsed.length;
        // Ignore the best and the worst elapsed times
        if(elapsed.length > 2) {
            count -= 2;
            ulong min = ulong.max;
            ulong max = ulong.min;
            foreach(i, e; elapsed) {
                if(e < min) {
                    min = e;
                    minIndex = i;
                } else if(e > max) {
                    max = e;
                    maxIndex = i;
                }
            }
        }
        this.average = 0;
        foreach(i, e; elapsed) {
            if(i != minIndex && i != maxIndex) {
                average += e;
            }
        }
        this.average /= count;
    }
}

void run(uint numKeys) {

    executeTasks!uint(numKeys);
    executeTasks!string(numKeys);
    
    auto stats = GC.stats();
    auto profileStats = GC.profileStats();
    writefln("╔═════════════════════════════════════════════════════════════════════");
    writefln("║ " ~ ansiWrap("GC Stats", Ansi.BLUE));
    writefln("║ Used .............. %s MB (%000,s bytes)", stats.usedSize/(1024*1024), stats.usedSize);
    writefln("║ Free .............. %s MB (%000,s bytes)", stats.freeSize/(1024*1024), stats.freeSize);
    writefln("║ Collections ....... %s", profileStats.numCollections);
    writefln("║ Collection time ... %.2f ms", profileStats.totalCollectionTime.total!"nsecs"/1000000.0);
    writefln("║ Pause time ........ %.2f ms", profileStats.totalPauseTime.total!"nsecs"/1000000.0);
    writefln("╚═════════════════════════════════════════════════════════════════════");
}
void executeTasks(T)(ulong numKeys) {
    foreach(d; getBenchmarks!T(numKeys)) {
        writefln("%s (%s)",d.label, T.stringof);
        uint iterations = 1000;

        auto maps = getMaps!T();
        Result[] results = maps.map!(it=>Result(it.name(), 0, new ulong[iterations])).array;

        foreach(j; 0..iterations) {

            foreach(i, map; maps) {
                map.reset();
                d.task.prepare(map, d.keys);

                StopWatch watch = StopWatch(AutoStart.no);
                watch.start();
                d.task.execute(map, d.keys);
                watch.stop();
                results[i].elapsed[j] = watch.peek().total!"nsecs";
            }
            GC.collect();
        }
        foreach(ref r; results) {
            r.calculateAverage();
        }

        ulong lowest = ulong.max;
        ulong highest = ulong.min;
        foreach(r; results) {
            lowest = r.average < lowest ? r.average : lowest;
            highest = r.average > highest ? r.average : highest;
        }
        foreach(r; results) {
            string colour = Ansi.YELLOW;
            if(r.average == lowest) {
                colour = Ansi.GREEN_BOLD;
            } else if(r.average == highest) {
                colour = Ansi.RED;
            } 
            ulong diff = r.average - lowest;
            string diffStr = diff == 0 ? "" : ansiWrap(" +%.5f (+%.1f%%)".format(diff/1_000_000.0, diff*100.0/lowest), Ansi.CYAN);
            writefln("%s%s", ansiWrap("  %s : %.5f".format(r.name, r.average/1_000_000.0), colour), diffStr);
        }
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
interface Map(T) {
    string name();
    string colour();
    void insert(T key, uint value);
    void remove(T key);
    uint* find(T key);
    ulong size();
    void reset();
}
final class BuiltinMap(T) : Map!T {
    uint[T] map;

    string name() {
        return "BuiltinMap ..............";
    }
    string colour() {
        return Ansi.BLUE_BOLD;
    }
    void insert(T key, uint value) {
        map[key] = value;
    }
    void remove(T key) {
        map.remove(key);
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
final class UnorderedMapWrapper(T, uint HASH) : Map!T {
    ulong capacity;
    float loadFactor;
    UnorderedMap!(T, uint, HASH) map;

    this(ulong capacity, float loadFactor) {
        this.capacity = capacity;
        this.loadFactor = loadFactor;
        reset();
    }

    string name() {
        return "UnorderedMap!%s (%s, %.2f)".format(HASH, capacity, loadFactor);
    }
    string colour() {
        return Ansi.GREEN_BOLD;
    }
    void insert(T key, uint value) {
        map.insert(key, value);
    }
    void remove(T key) {
        map.remove(key);
    }
    uint* find(T key) {
        return map.getPtr(key);
    }
    ulong size() {
        return map.size();
    }
    void reset() {
        map = new UnorderedMap!(T, uint, HASH)(capacity, loadFactor);
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
interface Task(T) {
    void prepare(Map!T map, T[] keys);
    void execute(Map!T map, T[] keys);

    final void insertKeys(Map!T map, T[] keys) {
        foreach(key; keys) {
            map.insert(key, 1);
        }
    }
}
final class InsertKeys(T) : Task!T {
    void prepare(Map!T map, T[] keys) {
        // Leave the map empty
    }
    void execute(Map!T map, T[] keys) {
        foreach(key; keys) {
            map.insert(key, 1);
        }
    }
}
final class RemoveKeys(T) : Task!T {
    void prepare(Map!T map, T[] keys) {
        insertKeys(map, keys);
    }
    void execute(Map!T map, T[] keys) {
        foreach(key; keys) {
            map.remove(key);
        }
    }
}
final class FindKeys(T) : Task!T{
    void prepare(Map!T map, T[] keys) {
        insertKeys(map, keys);
    }
    void execute(Map!T map, T[] keys) {
        foreach(key; keys) {
            uint* value = map.find(key);
        }
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
