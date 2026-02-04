module _tests.bench.bench;

public:

import core.stdc.stdlib       : malloc, calloc;
import core.atomic            : atomicLoad, atomicStore, atomicOp;
import core.thread            : Thread, thread_joinAll;
import core.memory            : GC;
import std.stdio              : File, writeln, writef, writefln;
import std.datetime.stopwatch : benchmark, StopWatch, AutoStart;
import std.random             : randomShuffle,uniform, Mt19937, unpredictableSeed;
import std.format             : format;
import std.algorithm          : permutations, map, sum, each, sort, reverse;
import std.typecons           : Tuple,tuple;
import std.range              : array,stride,join,iota;
import std.parallelism        : parallel, task;
import std.file               : tempDir, remove, exists;
import std.conv               : to;

import common;
import common.containers;
import common.io;
import common.utils;

import _tests.bench.bench_map;
import _tests.bench.bench_misc;
import _tests.bench.bench_set;
import _tests.bench.bench_sparse_array;

void runBenchmarks() {
    version(LDC) {
        writefln("Running benchmarks (LDC)");

        benchMap();
        //benchSet();
        //benchSparseArray();

        //testStringAppending();
        // testSimd();
        // benchmarkByteReader();
        // benchmarkAsyncArray();
        // benchmarkQueue();
        // benchmarkAsyncQueue();
        // benchmarkUtilities();
        // benchmarkList();
        // benchmarkStructCache();

    } else {
        writefln("Running benchmarks (DMD)");

        //testSimd();
        //testStringAppending();
    }
    writeln("All benchmarks finished");

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
//──────────────────────────────────────────────────────────────────────────────────────────────────
void executeBenchmarks(T)(Benchmark!T[] benchmarks) {
    foreach(d; benchmarks) {
        writefln("%s (%s)",d.label, T.stringof);
        uint iterations = 1000;

        auto subjects = d.task.getSubjects();
        auto results = subjects.map!(it=>BenchmarkResult(it.name(), 0, new ulong[iterations])).array;

        foreach(j; 0..iterations) {

            foreach(i, subject; subjects) {
                d.task.prepare(subject);

                StopWatch watch = StopWatch(AutoStart.no);
                watch.start();
                d.task.execute();
                watch.stop();
                results[i].elapsed[j] = watch.peek().total!"nsecs";
                results[i].finalResult = d.task.getFinalResult();
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
struct Benchmark(T) {
    string label;
    BenchmarkTask!T task;
}
interface BenchmarkTask(T) {
    void prepare(BenchmarkSubject!T subject);
    void execute();
    string getFinalResult();

    BenchmarkSubject!T[] getSubjects();
}
interface BenchmarkSubject(T) {
    string name();
}
struct BenchmarkResult {
    string name;
    ulong average;
    ulong[] elapsed;
    string finalResult;

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
//──────────────────────────────────────────────────────────────────────────────────────────────────
auto createUniqueKeys(T : uint)(ulong num) {
    T[] keys = new T[num];
    foreach(i; 0..num) {
        keys[i] = uniform(0, uint.max);
    }
    randomShuffle(keys);
    return keys;
}
auto createUniqueKeys(T : ulong)(ulong num) {
    T[] keys = new T[num];
    foreach(i; 0..num) {
        keys[i] = uniform(0, ulong.max);
    }
    randomShuffle(keys);
    return keys;
}
auto createUniqueKeys(T : float)(ulong num) {
    T[] keys = new T[num];
    foreach(i; 0..num) {
        keys[i] = uniform(0.0f, uint.max.as!float);
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
auto createDuplicateKeys(T : ulong)(ulong num) {
    T[] keys = new T[num];
    foreach(i; 0..num) {
        keys[i] = uniform(0, 100);
    }
    randomShuffle(keys);
    return keys;
}
auto createDuplicateKeys(T : float)(ulong num) {
    T[] keys = new T[num];
    foreach(i; 0..num) {
        keys[i] = uniform(0.0f, uint.max.as!float);
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
