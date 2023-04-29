module _tests.test_threads;

import std.stdio : writefln;
import common.threads;

void testThreads() {
    writefln("========--\nTesting threads\n==--");

    assert(Threads.getTotalHardwareThreads() == 16);

    import std.parallelism : task, taskPool;

    {   // Using taskPool

        // Create Task objects
        auto t1 = task!foo;
        auto t2 = task!(bar)(1);
        auto t3 = task!(() { return 3; });

        // Add them to the pool for execution
        taskPool().put(t1);
        taskPool().put(t2);
        taskPool().put(t3);

        // Wait for the results if required
        t1.yieldForce();
        assert(2 == t2.yieldForce());
        assert(3 == t3.yieldForce());
    }
}

void foo() {

}
int bar(int a) {
    return a+1;
}