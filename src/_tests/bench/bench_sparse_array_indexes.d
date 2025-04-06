module _tests.bench.bench_sparse_array_indexes;

import common;
import common.allocators;
import _tests.bench.bench;

void benchSparseArray() {
    writefln("================================================================");
    writefln(" Benchmarking SparseArrayIndexes");
    writefln("================================================================");

    run();
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void run() { 
    ulong numIndexes = 1_000_000;
    ulong capacity = 1024*1024*2;
    uint J = 100;

    {   // Display the number of bytes required
        auto ss = new SparseArrayIndexes();
        ss.add(capacity-1);
        writefln(" capacity = %s, num bytes used = %s", ss.capacity(), ss.numBytesUsed());

        // capacity | num bytes
        // ---------|----------
        // 2^21     | 786,416
    }

    ulong[] indexes = new ulong[numIndexes];
    foreach(i; 0..numIndexes) {
        indexes[i] = uniform(0UL, capacity);
    }

    writef("Adding %s indexes", numIndexes);
    StopWatch watch = StopWatch(AutoStart.no);
    foreach(j; 0..J) {

        auto s = new SparseArrayIndexes;

        watch.start();
        foreach(x; indexes) {
            s.add(x);
        }
        watch.stop();
    }
    writefln("        --> %.2f ms", watch.peek().total!"nsecs"/1000000.0);
    // [1438] -- 

    writef("Removing %s indexes", numIndexes);
    StopWatch watch2 = StopWatch(AutoStart.no);
    foreach(j; 0..J) {

        auto s = new SparseArrayIndexes;
        foreach(x; indexes) {
            s.add(x);
        }

        watch2.start();
        foreach(x; indexes) {
            s.remove(x);
        }
        watch2.stop();
    }
    writefln("      --> %.2f ms", watch2.peek().total!"nsecs"/1000000.0);
    // [1423] -- 

    writef("sparseIndexOf %s indexes", numIndexes);
    StopWatch watch3 = StopWatch(AutoStart.no);
    ulong accum = 0;
    foreach(j; 0..J) {

        auto s = new SparseArrayIndexes;
        foreach(x; indexes) {
            s.add(x);
        }

        watch3.start();
        foreach(x; indexes) {
            accum += s.sparseIndexOf(x);
        }
        watch3.stop();
    }
    writefln(" --> %.2f ms", watch3.peek().total!"nsecs"/1000000.0);
    // [4203] -- 

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
