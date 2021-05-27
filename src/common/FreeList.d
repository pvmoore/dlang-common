module common.FreeList;

import common;

/**
 * Keep track of index usage.
 * Allows for fast reuse of slots.
 */
final class FreeList {
private:
    uint[] list;
    uint next;
    uint numUsed;
public:
    this(uint length) {
        list.length = length;
        foreach(i; 0..length) {
            list[i] = i.as!int+1;
        }
        next = 0;
        numUsed = 0;
    }
    uint acquire() {
        if(numUsed==list.length) throw new Exception("FreeList is full");
        auto index = next;
        next = list[next];
        numUsed++;
        return index;
    }
    void release(uint index) {
        list[index] = next;
        next = index;
        numUsed--;
    }
    uint numFree() {
        return list.length.as!uint - numUsed;
    }
}

unittest {

import std.format;

void test() {
    auto fl = new FreeList(8);
    assert(fl.numFree() == 8);
    assert(fl.next == 0);
    assert(fl.list[0] == 1);
    assert(fl.list[7] == 8);

    // 0
    auto n1 = fl.acquire();
    assert(n1==0);
    assert(fl.list == [1,2,3,4,5,6,7,8]);
    assert(fl.numFree==7);
    assert(fl.next==1);

    // 0,1
    auto n2 = fl.acquire();
    assert(n2==1);
    assert(fl.list == [1,2,3,4,5,6,7,8]);
    assert(fl.numFree==6);
    assert(fl.next==2);

    // 0,1,2
    auto n3 = fl.acquire();
    assert(n3==2);
    assert(fl.list == [1,2,3,4,5,6,7,8]);
    assert(fl.numFree==5);
    assert(fl.next==3);

    // 1,2
    fl.release(0);
    assert(fl.list == [3,2,3,4,5,6,7,8]);
    assert(fl.numFree==6);
    assert(fl.next==0);

    // 0,1,2
    assert(fl.acquire()==0 && fl.next==3 && fl.numFree==5);
    // 0,1,2,3
    assert(fl.acquire()==3 && fl.next==4 && fl.numFree==4);
    // 0,1,2,3,4
    assert(fl.acquire()==4 && fl.next==5 && fl.numFree==3);
    assert(fl.list == [3,2,3,4,5,6,7,8]);

    // 0,2,3,4
    fl.release(1);
    assert(fl.next==1);
    assert(fl.list == [3,5,3,4,5,6,7,8]);
    assert(fl.numFree==4);

    // 0,1,2,3,4
    assert(fl.acquire()==1 && fl.next==5 && fl.numFree==3);
    // 0,1,2,3,4,5
    assert(fl.acquire()==5 && fl.next==6 && fl.numFree==2);
    // 0,1,2,3,4,5,6
    assert(fl.acquire()==6 && fl.next==7 && fl.numFree==1);

    // 0,1,2,3,4,5
    fl.release(6);
    assert(fl.next==6);
    assert(fl.list == [3,5,3,4,5,6,7,8]);
    assert(fl.numFree==2);

    // 0,1,2,3,4,5,6
    assert(fl.acquire()==6 && fl.next==7 && fl.numFree==1);
    // 0,1,2,3,4,5,6,7
    assert(fl.acquire()==7 && fl.next==8 && fl.numFree==0);

    Exception exception;
    try{
        fl.acquire();
    }catch(Exception e) {
        exception = e;
    }
    assert(exception);
}
test();

} // unittest