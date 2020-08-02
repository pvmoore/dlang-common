module test_containers;

import std.stdio  : writefln;
import std.format : format;

import common.containers;

void testContainers() {
    testArray();
    testList();
    testPriorityQueue();
    testQueue();
    testSet();
    testSparseArray();
    testStack();
    testTreeList();
}

void testArray() {
    writefln("==-- Testing Array --==");
    auto a = new Array!int;
    assert(a.empty && a.length==0);

    // add
    for(auto i=0; i<5; i++) a.add(i);
    assert(a.length==5 && !a.empty && a==[0,1,2,3,4]);
    a.add(5);
    assert(a.length==6 && a[5]==5);
    // removeAt
    assert(a.removeAt(0)==0 && a.length==5);
    assert(a==[1,2,3,4,5]);

    assert(a.removeAt(2)==3 && a.length==4);
    assert(a==[1,2,4,5]);

    assert(a.removeAt(3)==5 && a.length==3);
    assert(a==[1,2,4]);

    // removeAt array
    a.clear(); a.add([0,1,2,3,4]);
    a.removeAt(0, 2);
    assert(a==[2,3,4]);
    a.removeAt(1,2);
    assert(a==[2]);
    a.removeAt(0,1);
    assert(a==[]);
    a.add([0,1,2,3,4]);
    a.removeAt(0,5);
    assert(a==[]);
    a.add([1,2,3]);
    a.removeAt(0,0);
    assert(a==[1,2,3]);
    a.removeAt(1, 1000);
    assert(a==[1] && a.length==1);

    {   // remove
        a.clear(); a.add([0,1,2,3,4]);
        assert(a.remove(2)==2 && a.length==4 && a==[0,1,3,4]);
        assert(a.remove(7)==0 && a.length==4 && a==[0,1,3,4]);
        assert(a.remove(0)==0 && a.length==3 && a==[1,3,4]);
        assert(a.remove(4)==4 && a.length==2 && a==[1,3]);
    }

    // add array
    a.clear(); a.add([1,2,4]);
    a.add([10,11,12]);
    assert(a.length==6 && a==[1,2,4,10,11,12]);

    a.add([13,14,15,16]);
    assert(a.length==10 && a==[1,2,4,10,11,12,13,14,15,16]);

    // insertAt
    a.clear();
    a.add(0).add(1).add(2);
    a.insertAt(0, 99);
    assert(a.length==4 && a==[99,0,1,2]);
    a.insertAt(1, 55);
    assert(a.length==5 && a==[99,55,0,1,2]);
    a.insertAt(4, 33);
    assert(a.length==6 && a==[99,55,0,1,33,2]);
    a.insertAt(6, 11);
    assert(a.length==7 && a==[99,55,0,1,33,2,11]);

    // insertAt array
    a.clear(); a.add([0,1,2,3,4]);
    a.insertAt(0, [8,9]);
    assert(a==[8,9,0,1,2,3,4] && a.length==7);
    a.insertAt(0, []);
    assert(a==[8,9,0,1,2,3,4] && a.length==7);
    a.insertAt(2, [90]);
    assert(a==[8,9,90,0,1,2,3,4] && a.length==8);
    a.insertAt(7, [100]);
    assert(a==[8,9,90,0,1,2,3,100,4] && a.length==9);
    a.insertAt(9, [200]);
    assert(a==[8,9,90,0,1,2,3,100,4,200] && a.length==10);

    // opIndex(), opSlice and opDollar
    a.clear();
    a.add([1,2,3]);
    assert(a[]==[1,2,3]);
    assert(a[0..2]==[1,2] && a[0..1]==[1]);
    assert(a[0..$]==[1,2,3]);

    // move (forwards)
    a.clear();
    a.add([0,1,2,3,4]);
    a.move(2,0);
    assert(a==[2,0,1,3,4]);
    a.move(4,3);
    assert(a==[2,0,1,4,3]);
    a.move(4,4);
    assert(a==[2,0,1,4,3]);
    a.move(4,0);
    assert(a==[3,2,0,1,4]);
    // move (backwards)
    a.clear();
    a.add([0,1,2,3,4]);
    a.move(1,3);
    assert(a==[0,2,3,1,4]);
    a.move(0,4);
    assert(a==[2,3,1,4,0]);

    { // opCatAssign
        auto array = new Array!char;
        array ~= 'a';
        assert(array.length==1 && array[0]=='a');
        array ~= ['b','c'];
        assert(array.length==3 && array==['a','b','c']);
    }

    {// opApply
        auto array = new Array!int;
        array.add([1,5,7]);
        int total = 0;
        foreach(v; array) {
            total += v;
        }
        assert(total==13);

        total = 0;
        foreach(i, v; array) {
            total += i;
            total += v;
        }
        assert(total==13+3);
    }
}
void testList() {
    writefln("--== Testing List ==--");

    auto a = new List!int;
    assert(a.empty && a.length==0);

    // add
    for(auto i=0; i<5; i++) a.add(i);
    assert(a.length==5 && !a.empty && a==[0,1,2,3,4]);
    a.add(5);
    assert(a.length==6 && a[5]==5);

    // remove
    assert(a.remove(0)==0 && a.length==5);
    assert(a==[1,2,3,4,5]);

    assert(a.remove(2)==3 && a.length==4);
    assert(a==[1,2,4,5]);

    assert(a.remove(3)==5 && a.length==3);
    assert(a==[1,2,4]);

    assert(a.remove(2)==4 && a.length==2);
    assert(a==[1,2]);

    assert(a.remove(1)==2 && a.length==1);
    assert(a==[1]);

    assert(a.remove(0)==1 && a.length==0);
    assert(a==[]);

    // insert
    a.clear();
    a.add(0).add(1).add(2);
    a.insert(99, 0);
    assert(a.length==4 && a==[99,0,1,2]);
    a.insert(55, 1);
    assert(a.length==5 && a==[99,55,0,1,2]);
    a.insert(33, 4);
    assert(a.length==6 && a==[99,55,0,1,33,2]);
    a.insert(11, 6);
    assert(a.length==7 && a==[99,55,0,1,33,2,11]);
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
void testSparseArray() {
    writefln("--== Testing SparseArray ==--");

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