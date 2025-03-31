module _tests.bench.bench_map;

import common;
import _tests.bench.bench;

void benchMap() {
    writefln("================================================================");
    writefln(" Benchmarking Maps ");
    writefln("================================================================");

    run(100_000, [
        cast(Map)new BuiltinMap(),
        new UnorderedMapWrapper!0(0.9), 
        new UnorderedMapWrapper!0(0.8),
        new UnorderedMapWrapper!0(0.75),
        new UnorderedMapWrapper!1(0.75),
        new UnorderedMapWrapper!2(0.75),
        new UnorderedMapWrapper!3(0.75),
        new UnorderedMapWrapper!4(0.75),
        new UnorderedMapWrapper!5(0.75),
        new UnorderedMapWrapper!0(0.6),
        new UnorderedMapWrapper!1(0.6),
        new UnorderedMapWrapper!2(0.6),
        new UnorderedMapWrapper!3(0.6),
        new UnorderedMapWrapper!4(0.6),
        new UnorderedMapWrapper!5(0.6),
        new UnorderedMapWrapper!0(0.5)
    ]);
}
private:

void run(uint numKeys, Map[] maps) {
    uint[] uniqueKeys = new uint[numKeys];
    uint[] duplicateKeys = new uint[numKeys];

    foreach(i; 0..numKeys) {
        uniqueKeys[i] = i;
        duplicateKeys[i] = i % 100;
    }

    randomShuffle(uniqueKeys);
    randomShuffle(duplicateKeys);

    static struct Data {
        ulong function(Map, uint[]) func;
        string label;
        uint[] keys;
    }
    static struct Result {
        string name;
        ulong average;
        ulong[] elapsed;
    }

    auto data = [
        Data(&insertKeys, "Insert unique", uniqueKeys),
        Data(&insertKeys, "Insert duplicate", duplicateKeys),
        Data(&removeKeys, "Remove unique", uniqueKeys),
        Data(&removeKeys, "Remove duplicate", duplicateKeys),
        Data(&findKeys, "Find unique", uniqueKeys),
        Data(&findKeys, "Find duplicate", duplicateKeys)];

    ulong calculateAverage(ulong[] elapsed) {
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
        ulong average = 0;
        foreach(i, e; elapsed) {
            if(i != minIndex && i != maxIndex) {
                average += e;
            }
        }
        return average / count;
    }    

    foreach(d; data) {
        writefln(d.label);
        uint iterations = 1000;
        Result[] results = maps.map!(it=>Result(it.name(), 0, new ulong[iterations])).array;

        foreach(j; 0..iterations) {
            foreach(i, map; maps) {
                results[i].elapsed[j] = d.func(map, d.keys);
            }
            GC.collect();
        }
        foreach(ref r; results) {
            r.average = calculateAverage(r.elapsed);
        }
        ulong lowest = ulong.max;
        ulong highest = ulong.min;
        foreach(ref r; results) {
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

interface Map {
    string name();
    string colour();
    void insert(uint key, uint value);
    void remove(uint key);
    uint* find(uint key);
    ulong size();
    void reset();
}

final class BuiltinMap : Map {
    uint[uint] map;

    string name() {
        return "BuiltinMap ..........";
    }
    string colour() {
        return Ansi.BLUE_BOLD;
    }
    void insert(uint key, uint value) {
        map[key] = value;
    }
    void remove(uint key) {
        map.remove(key);
    }
    uint* find(uint key) {
        return key in map;
    }
    ulong size() {
        return map.length;
    }
    void reset() {
        map = null;
    }
}
final class UnorderedMapWrapper(uint HASH) : Map {
    float loadFactor;
    UnorderedMap!(uint, uint, HASH) map;

    this(float loadFactor) {
        this.loadFactor = loadFactor;
        reset();
    }

    string name() {
        return "UnorderedMap!%s (%.2f)".format(HASH, loadFactor);
    }
    string colour() {
        return Ansi.GREEN_BOLD;
    }
    void insert(uint key, uint value) {
        map.insert(key, value);
    }
    void remove(uint key) {
        map.remove(key);
    }
    uint* find(uint key) {
        return map.getPtr(key);
    }
    ulong size() {
        return map.size();
    }
    void reset() {
        map = new UnorderedMap!(uint, uint, HASH)(16, loadFactor);
    }
}

ulong insertKeys(Map map, uint[] keys) {
    StopWatch watch = StopWatch(AutoStart.no);

    map.reset();
    
    watch.start();
    foreach(key; keys) {
        map.insert(key, 1);
    }
    watch.stop();
    return watch.peek().total!"nsecs";
}
ulong removeKeys(Map map, uint[] keys) {
    StopWatch watch = StopWatch(AutoStart.no);

    map.reset();

    // Add the keys
    foreach(k; keys) {
        map.insert(k, 1);
    }
    
    watch.start();
    foreach(key; keys) {
        map.remove(key);
    }
    watch.stop();
    return watch.peek().total!"nsecs";
}
ulong findKeys(Map map, uint[] keys) {
    StopWatch watch = StopWatch(AutoStart.no);

    map.reset();

    // Add the keys
    foreach(k; keys) {
        map.insert(k, 1);
    }
    
    watch.start();
    foreach(key; keys) {
        uint* value = map.find(key);
    }
    watch.stop();
    return watch.peek().total!"nsecs";
} 

