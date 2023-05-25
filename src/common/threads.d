module common.threads;

/**
 * Provide some common thread functionality.
 *
 *
 */
import common.all;

private {
    import std.parallelism  : defaultPoolThreads, totalCPUs, task, Task, taskPool, TaskPool;
    import std.concurrency  : scheduler, spawn, thisTid;
}

public {
    import core.thread              : Thread;
    import core.thread.threadgroup  : ThreadGroup;
    import std.concurrency          : Tid;
}

public final class Threads {
public:
    static int getTotalHardwareThreads() { return totalCPUs; }
    static Tid getCurrentTid() { return thisTid; }

private:
}