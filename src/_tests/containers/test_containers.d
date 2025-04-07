module _tests.containers.test_containers;

import std.stdio  : writef, writefln;
import std.format : format;
import std.random : uniform, uniform01, Mt19937, unpredictableSeed;

import common.all;
import _tests.containers.test_sparse_array;
import _tests.containers.test_unordered_map;
import _tests.test : RUN_SUBSET;

void testContainers() {
    static if(RUN_SUBSET) {
        testSparseArray();
    } else {
        testCircularBuffer();
        testList();
        testPriorityQueue();
        testQueue();
        testSet();
        testSparseArray();
        testUnorderedMap();
        testStack();
        testTreeList();
        testAsyncQueue();
        testUniqueList();
    }
}

void testCircularBuffer() {
    writefln("==-- Testing CircularBuffer --==");

    {   // invalid length
        try{
            new CircularBuffer!int(7);
            assert(false);
        }catch(Exception e) {}
    }
    {   // isEmpty, size, add and take
        auto buf = new CircularBuffer!int(8);
        assert(buf.isEmpty());
        assert(buf.size()==0);

        buf.add(1);
        assert(!buf.isEmpty());
        assert(buf.size()==1);

        assert(1==buf.take());
        assert(buf.isEmpty());
        assert(buf.size()==0);

        buf.add(1);
        buf.add(2);
        buf.add(3);
        assert(buf.size()==3);

        assert(1==buf.take());
        assert(2==buf.take());
        assert(3==buf.take());
        assert(buf.isEmpty());
        assert(buf.size()==0);
    }
    {   // fully populated
        auto buf = new CircularBuffer!int(8);
        buf.add(1);
        buf.add(2);
        buf.add(3);
        buf.add(4);
        buf.add(5);
        buf.add(6);
        buf.add(7);
        buf.add(8);
        assert(buf.size()==8, "%s".format(buf.size()));

        assert(1==buf.take());
        assert(2==buf.take());
        assert(3==buf.take());
        assert(4==buf.take());
        assert(5==buf.take());
        assert(6==buf.take());
        assert(7==buf.take());
        assert(8==buf.take());
        assert(buf.isEmpty());
        assert(buf.size()==0);
    }
    {   // wrap
        auto buf = new CircularBuffer!int(8);

        buf.add(1).add(2).add(3).add(4).add(5).add(6).add(7).add(8);

        assert(1==buf.take());
        assert(2==buf.take());
        assert(3==buf.take());
        assert(4==buf.take());

        assert(buf.size()==4);

        buf.add(9);
        buf.add(10);
        buf.add(11);
        buf.add(12);
        assert(buf.size()==8);

        assert(5==buf.take());
        assert(6==buf.take());
        assert(7==buf.take());
        assert(8==buf.take());

        assert(buf.size()==4);

        buf.add(13);
        buf.add(14);
        buf.add(15);
        assert(buf.size()==7);

        assert(9==buf.take());
        assert(10==buf.take());
        assert(11==buf.take());
        assert(12==buf.take());
        assert(13==buf.take());
        assert(14==buf.take());
        assert(15==buf.take());
        assert(buf.size()==0);
    }
    {   // can't add if buffer is full
        try{
            auto buf = new CircularBuffer!int(4);
            buf.add(1);
            buf.add(2);
            buf.add(3);
            buf.add(4);
            buf.add(5);
            assert(false);
        }catch(Exception e) {}
    }
    {   // can't take if buffer is empty
        try{
            auto buf = new CircularBuffer!int(4);
            buf.take();
            assert(false);
        }catch(Exception e) {}
    }

    writefln("==-- Testing ContiguousCircularBuffer --==");

    {   // invalid length
        try{
            new ContiguousCircularBuffer!int(7);
            assert(false);
        }catch(Exception e) {}
    }
    {   // isEmpty, size, add and take
        auto buf = new ContiguousCircularBuffer!int(8);
        assert(buf.isEmpty());
        assert(buf.size()==0);
        assert(buf.slice()==[]);

        buf.add(1);
        assert(!buf.isEmpty());
        assert(buf.size()==1);
        assert(buf.slice()==[1]);

        assert(1==buf.take());
        assert(buf.isEmpty());
        assert(buf.size()==0);

        buf.add(1);
        buf.add(2);
        buf.add(3);
        assert(buf.size()==3);
        assert(buf.slice()==[1,2,3]);

        assert(1==buf.take());
        assert(2==buf.take());
        assert(3==buf.take());
        assert(buf.isEmpty());
        assert(buf.size()==0);
        assert(buf.slice()==[]);
    }
    {   // fully populated
        auto buf = new ContiguousCircularBuffer!int(8);
        buf.add(1);
        buf.add(2);
        buf.add(3);
        buf.add(4);
        buf.add(5);
        buf.add(6);
        buf.add(7);
        buf.add(8);
        assert(buf.size()==8, "%s".format(buf.size()));
        assert(buf.slice()==[1,2,3,4,5,6,7,8]);

        assert(1==buf.take());
        assert(2==buf.take());
        assert(3==buf.take());
        assert(4==buf.take());
        assert(5==buf.take());
        assert(6==buf.take());
        assert(7==buf.take());
        assert(8==buf.take());
        assert(buf.isEmpty());
        assert(buf.size()==0);
        assert(buf.slice()==[]);
    }
    {   // wrap
        auto buf = new ContiguousCircularBuffer!int(8);

        buf.add(1).add(2).add(3).add(4).add(5).add(6).add(7).add(8);
        assert(buf.slice()==[1,2,3,4,5,6,7,8]);

        assert(1==buf.take());
        assert(2==buf.take());
        assert(3==buf.take());
        assert(4==buf.take());

        assert(buf.size()==4);
        assert(buf.slice()==[5,6,7,8]);

        buf.add(9);
        buf.add(10);
        buf.add(11);
        buf.add(12);
        assert(buf.size()==8);
        assert(buf.slice()==[5,6,7,8,9,10,11,12]);

        assert(5==buf.take());
        assert(6==buf.take());
        assert(7==buf.take());
        assert(8==buf.take());

        assert(buf.size()==4);
        assert(buf.slice()==[9,10,11,12]);

        buf.add(13);
        buf.add(14);
        buf.add(15);
        assert(buf.size()==7);
        assert(buf.slice()==[9,10,11,12,13,14,15]);

        assert(9==buf.take());
        assert(10==buf.take());
        assert(11==buf.take());
        assert(12==buf.take());
        assert(13==buf.take());
        assert(14==buf.take());
        assert(15==buf.take());
        assert(buf.size()==0);
        assert(buf.slice()==[]);
    }
    {   // can't add if buffer is full
        try{
            auto buf = new ContiguousCircularBuffer!int(4);
            buf.add(1);
            buf.add(2);
            buf.add(3);
            buf.add(4);
            buf.add(5);
            assert(false);
        }catch(Exception e) {}
    }
    {   // can't take if buffer is empty
        try{
            auto buf = new ContiguousCircularBuffer!int(4);
            buf.take();
            assert(false);
        }catch(Exception e) {}
    }
}
void testList() {
    writefln("--== Testing List ==--");

    auto a = new List!int;
    assert(a.isEmpty() && a.length()==0);

    // add
    for(auto i=0; i<5; i++) a.add(i);
    assert(a.length()==5 && !a.isEmpty() && a==[0,1,2,3,4]);
    a.add(5);
    assert(a.length()==6 && a[5]==5);

    // remove
    assert(a.remove(0)==0 && a.length()==5);
    assert(a==[1,2,3,4,5]);

    assert(a.remove(2)==3 && a.length()==4);
    assert(a==[1,2,4,5]);

    assert(a.remove(3)==5 && a.length()==3);
    assert(a==[1,2,4]);

    assert(a.remove(2)==4 && a.length()==2);
    assert(a==[1,2]);

    assert(a.remove(1)==2 && a.length()==1);
    assert(a==[1]);

    assert(a.remove(0)==1 && a.length()==0);
    assert(a==[]);

    // insert
    a.clear();
    a.add(0).add(1).add(2);
    a.insert(99, 0);
    assert(a.length()==4 && a==[99,0,1,2]);
    a.insert(55, 1);
    assert(a.length()==5 && a==[99,55,0,1,2]);
    a.insert(33, 4);
    assert(a.length()==6 && a==[99,55,0,1,33,2]);
    a.insert(11, 6);
    assert(a.length()==7 && a==[99,55,0,1,33,2,11]);
}
void testPriorityQueue() {
    writefln("Testing PriorityQueue...");

    {
        auto q = makeHighPriorityQueue!int;
        assert(q.empty && q.length==0);

        q.push(5);
        assert(!q.empty && q.length==1 && q.asArray == [5]);

        assert(q.push(3).length==2 && q.asArray == [3, 5]);
        assert(q.push(7).length==3 && q.asArray == [3, 5, 7]);
        assert(q.push(1).asArray == [1, 3, 5, 7]);
        assert(q.push(10).asArray == [1, 3, 5, 7, 10]);
        assert(q.push(10).asArray == [1, 3, 5, 7, 10, 10]);
        assert(q.push(9).asArray == [1, 3, 5, 7, 9, 10, 10]);

        assert(q.pop() == 10 && q.length==6 && q.asArray==[1, 3, 5, 7, 9, 10]);
        assert(q.pop() == 10 && q.length==5 && q.asArray==[1, 3, 5, 7, 9]);
        assert(q.pop() == 9 && q.length==4 && q.asArray==[1, 3, 5, 7]);
        assert(q.pop() == 7 && q.length==3 && q.asArray==[1, 3, 5]);
        assert(q.pop() == 5 && q.length==2 && q.asArray==[1, 3]);
        assert(q.pop() == 3 && q.length==1 && q.asArray==[1]);
        assert(q.pop() == 1 && q.length==0 && q.empty && q.asArray==[]);

        assert(q.push(10).length==1 && q.asArray==[10]);
        assert(q.push(0).length==2 && q.asArray==[0, 10]);

        assert(q.clear().length == 0 && q.empty && q.asArray==[]);
    }
    {   // High priority queue with struct values
        struct S {
            int value;

            int opCmp(inout S other) const {
                return value==other.value ? 0 : value < other.value ? -1 : 1;
            }
            bool opEquals(inout S other) const  {
                return value == other.value;
            }
        }
        auto q = makeHighPriorityQueue!S;

        assert(q.push(S(1)).length==1 && q.asArray==[ S(1) ]);
        assert(q.push(S(3)).length==2 && q.asArray==[ S(1), S(3) ]);
        assert(q.push(S(2)).length==3 && q.asArray==[ S(1), S(2), S(3) ]);
        assert(q.pop() == S(3) && q.length == 2 && q.asArray == [S(1), S(2)]);
    }
    {   // Low priority queue
        auto q = makeLowPriorityQueue!int;
        assert(q.empty && q.length==0);

        q.push(5);
        assert(!q.empty && q.length==1 && q.asArray == [5]);

        assert(q.push(3).length==2 && q.asArray == [5, 3]);
        assert(q.push(7).length==3 && q.asArray == [7, 5, 3]);
        assert(q.push(1).asArray == [7,5,3,1]);
        assert(q.push(10).asArray == [10,7,5,3,1]);
        assert(q.push(10).asArray == [10,10,7,5,3,1]);
        assert(q.push(9).asArray == [10,10,9,7,5,3,1]);

        assert(q.pop() == 1 && q.length==6 && q.asArray==[10,10,9,7,5,3]);
        assert(q.pop() == 3 && q.length==5 && q.asArray==[10,10,9,7,5]);
        assert(q.pop() == 5 && q.length==4 && q.asArray==[10,10,9,7]);
        assert(q.pop() == 7 && q.length==3 && q.asArray==[10,10,9]);
        assert(q.pop() == 9 && q.length==2 && q.asArray==[10,10]);
        assert(q.pop() == 10 && q.length==1 && q.asArray==[10]);
        assert(q.pop() == 10 && q.length==0 && q.empty && q.asArray==[]);
    }
}
void testQueue() {
    writefln("--== Testing Queue ==--");

    auto q = new Queue!int(1024);
    assert(q.length==0 && q.empty);

    q.push(1);
    assert(q.length==1 && !q.empty);

    q.push(2).push(3);
    assert(q.length==3);

    assert(q.pop()==1 && q.length==2);
    assert(q.pop()==2 && q.length==1);
    assert(q.pop()==3 && q.length==0 && q.empty);

    q.push(30);
    q.clear();
    assert(q.length==0 && q.empty);

    // drain
    int[] temp = new int[4];
    q.clear();
    q.push(1).push(3).push(7);
    assert(q.drain(temp)==3 && temp[0..3]==[1,3,7]);

    q.push(1).push(3).push(7).push(11).push(13);
    assert(q.drain(temp)==4 && temp[0..4]==[1,3,7,11]);

    assert(q.drain(temp)==1 && temp[0]==13);

    assert(q.drain(temp)==0);

    /// valuesDup
    {
        auto queue = new Queue!int(1024);
        queue.push(1).push(2).push(3);
        assert(queue.valuesDup() == [1,2,3]);
        queue.pop();
        assert(queue.valuesDup() == [2,3]);
    }
    /// pushToFront
    {
        auto queue = new Queue!int(1024);
        queue.push(1).push(2).push(3);
        queue.pushToFront(4);
        assert(queue.valuesDup() == [4,1,2,3]);
        queue.pop();
        assert(queue.valuesDup() == [1,2,3]);
    }
}
void testSet() {
    writefln("--== Testing Set ==--");

    {
        auto s = new Set!int;
        assert(s.empty && s.length==0);

        s.add(2).add(4);
        assert(!s.empty && s.length==2);
        assert(s.contains(2) && s.contains(4));

        s.add(2).add(3);
        assert(!s.empty && s.length==3);
        assert(s.contains(2) && s.contains(3) && s.contains(4));

        assert(s.remove(2)==true);
        assert(s.length==2);

        assert(s.remove(1)==false);
        assert(s.length==2);

        assert(s.values==[3,4] || s.values==[4,3]);
    }

    { // ==
        auto s1 = new Set!int;
        auto s2 = new Set!int;
        auto s3 = new Set!float;

        assert(s1==s2);
        assert(s1!=s3);

        s1.add([1,20,30,40,500]);
        s2.add([500,40,30,20,1]);
        writefln("s1 = %s", s1.values);
        writefln("s2 = %s", s2.values);
        assert(s1==s2);
        s1.add(2);
        assert(s1!=s2);
        s2.add(2);
        assert(s1==s2);
    }
}
void testUniqueList() {
    writefln("--== Testing UniqueList ==--");

    {   // Set functionality
        auto s = new UniqueList!int;
        assert(s.empty && s.length==0);

        s.add(2).add(4);
        assert(!s.empty && s.length==2);
        assert(s.contains(2) && s.contains(4));

        s.add(2).add(3);
        assert(!s.empty && s.length==3);
        assert(s.contains(2) && s.contains(3) && s.contains(4));

        assert(s.remove(2)==true);
        assert(s.length==2);

        assert(s.remove(1)==false);
        assert(s.length==2);

        assert(s.values()==[4,3], "%s".format(s.values()));

        s.clear();
        assert(s.empty && s.length==0);
    }
    {
        auto s = new UniqueList!int;
        s.add(1).add(2).add(3).add(4);

        writefln("%s", s);
        assert(s == [1,2,3,4]);

        s.clear();
        s.add(4);
        s.add([3,2,1]);

        writefln("%s", s);
        assert(s == [4,3,2,1]);
    }
}
void testStack() {
    writefln("--== Testing Stack ==--");
    auto stack = new Stack!uint(10);
    assert(stack==[] && stack.length==0 && stack.empty);
    writefln("%s", stack);

    stack.push(13);
    assert(stack==[13] && stack.length==1 && !stack.empty);
    writefln("%s", stack);

    stack.push(17);
    assert(stack==[13,17] && stack.length==2 && !stack.empty);
    assert(stack[]==[13,17]);
    writefln("%s", stack);

    assert(stack.pop()==17);
    assert(stack==[13] && stack.length==1 && !stack.empty);
    writefln("%s", stack);

    assert(stack.pop()==13 && stack.length==0 && stack.empty);
    assert(stack[]==[]);

    { // peek
        auto s = new Stack!int;
        assert(s.peek()==0);
        assert(s.peek(-1)==0);
        assert(s.peek(1)==0);

        s.push(1);
        assert(s.peek()==1);
        assert(s.peek(0)==1);

        s.push(2);
        assert(s.peek()==2);
        assert(s.peek(0)==2);
        assert(s.peek(1)==1);

        s.push(3);
        assert(s.peek()==3);
        assert(s.peek(0)==3);
        assert(s.peek(1)==2);
        assert(s.peek(2)==1);

        s.pop();
        assert(s.peek()==2);
        s.pop();
        assert(s.peek()==1);
        s.pop();
        assert(s.peek()==0);
    }
}
void testTreeList() {
    writefln("--== Testing TreeList ==--");

    static class A {
        int a;
        this(int a) { this.a = a; }
        alias opCmp = Object.opCmp;
        int opCmp(A o) { return o.a==a ? 0 : o.a<a ? 1 : -1; }
        override bool opEquals(Object o) {
            return a==(cast(A)o).a;
        }
        override string toString() { return "%s".format(a); }
    }
    auto tree = new TreeList!A;
    //writefln("tree=%s", tree);

    assert(tree.empty && tree.length==0);

    tree.add(new A(10));
    assert(!tree.empty && tree.length==1 && tree==[new A(10)]);

    tree.add(new A(30));
    assert(tree.remove(new A(30)));
    assert(false==tree.remove(new A(30)));

    auto tree2 = new TreeList!int;
    tree2.add(20);
    tree2.add(5);
    tree2.add(7);
    tree2.add(15);
    tree2.add(17);
    tree2.add(30);
    tree2.add(2);
    assert(tree2.length==7);
    assert(tree2==[2,5,7,15,17,20,30]);

    auto tree3 = new TreeList!int;
    tree3.add(20);
    tree3.add(5);
    tree3.add(7);
    tree3.add(15);
    tree3.add(17);
    tree3.add(30);
    tree3.add(2);
    assert(tree3.length==7);
    assert(tree3==[2,5,7,15,17,20,30]);
    writefln("%s", tree2);
    writefln("%s", tree3);
    assert(tree3==tree2);


    writefln("tree=%s", tree2);
}
void testAsyncQueue() {
    writefln("==-- Testing AsyncQueue --==");

    // Tests for SCSP (single producer / single consumer)

    {   // drain
        auto q = makeSPSCQueue!int(8);
        assert(q.empty() && q.length()==0);

        q.push(1).push(2).push(3).push(4).push(5);
        assert(!q.empty() && q.length==5);

        assert(q.pop()==1 && q.length()==4);

        // 2,3,4,5
        int[2] sink;
        assert(2 == q.drain(sink));
        assert(sink == [2,3]);

        q.push(6).push(7).push(8);
        assert(q.length()==5);

        // 4,5,6,7,8
        int[3] sink2;
        assert(3==q.drain(sink2) && q.length()==2);
        assert(sink2 == [4,5,6]);

        q.push(9).push(10).push(11);
        assert(q.length()==5);

        // 7,8,9,10,11
        int[5] sink3;
        assert(5 == q.drain(sink3));
        assert(q.length()==0);
        assert(sink3 == [7,8,9,10,11]);
    }
}
