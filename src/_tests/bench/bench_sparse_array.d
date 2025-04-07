module _tests.bench.bench_sparse_array;

import common;
import common.containers;
import _tests.bench.bench;

void benchSparseArray() {
    writefln("================================================================");
    writefln(" Benchmarking SparseArray");
    writefln("================================================================");

    run();
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void run() { 
    ulong numIndexes = 50_000;
    ulong capacity = 1024*1024*4;
    uint J = 100;

    ulong[] indexes = new ulong[numIndexes];
    uint[] values = new uint[numIndexes];
    foreach(i; 0..numIndexes) {
        indexes[i] = uniform(0UL, capacity);
        values[i] = uniform(0, uint.max);
    }

    writef("Adding %s indexes", numIndexes);
    StopWatch watch = StopWatch(AutoStart.no);
    foreach(j; 0..J) {

        auto s = new SparseArray!uint;

        watch.start();
        foreach(i; 0..indexes.length) {
            s[indexes[i]] = values[i];
        }
        watch.stop();
    }
    writefln("        --> %.2f ms", watch.peek().total!"nsecs"/1000000.0);
    // [4200]

    writef("Removing %s indexes", numIndexes);
    StopWatch watch2 = StopWatch(AutoStart.no);
    foreach(j; 0..J) {

        auto s = new SparseArray!uint;
        foreach(i; 0..indexes.length) {
            s[indexes[i]] = values[i];
        }

        watch2.start();
        foreach(x; indexes) {
            s.remove(x);
        }
        watch2.stop();
    }
    writefln("      --> %.2f ms", watch2.peek().total!"nsecs"/1000000.0);
    // [3200]

    writef("get %s indexes", numIndexes);
    StopWatch watch3 = StopWatch(AutoStart.no);
    ulong accum = 0;
    foreach(j; 0..J) {

        auto s = new SparseArray!uint;
        foreach(i; 0..indexes.length) {
            s[indexes[i]] = values[i];
        }

        watch3.start();
        foreach(x; indexes) {
            accum += s[x];
        }
        watch3.stop();
    }
    writefln(" --> %.2f ms", watch3.peek().total!"nsecs"/1000000.0);
    // [272]

    writefln("accum = %s", accum);

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
