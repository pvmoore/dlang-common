module _tests.containers.test_unique_list;

import common;
import common.containers;
import _tests.test;

void testUniqueList() {
    writefln("----------------------------");
    writefln(" Testing UniqueList");
    writefln("----------------------------");

    {   
        writefln(" new UniqueList()");
        auto s = new UniqueList!int;
        assert(s.isEmpty() && s.length==0);
    }
    {
        writefln(" add()");
        auto s = new UniqueList!int;
        s.add(2).add(4);
        assert(!s.isEmpty());
        assert(s.length()==2);
        assert(s.contains(2));
        assert(s.contains(4));

        s.add(2).add(3);
        assert(s.length==3);
        assert(s.contains(2));
        assert(s.contains(3));
        assert(s.contains(4));
    }
    {
        writefln(" add([])");
        auto s = new UniqueList!int;
        s.add([2,4,2]);
        assert(!s.isEmpty());
        assert(s.length()==2);
        assert(s.contains(2));
        assert(s.contains(4));
    }
    {
        writefln(" remove()");
        auto s = new UniqueList!int;
        s.add([2,4,3]);
        assert(s.length()==3); 

        assert(s.remove(2)==true);
        assert(s.length==2);

        assert(s.remove(1)==false);
        assert(s.length==2);

        assert(s.values()==[4,3], "%s".format(s.values()));
    }
    {
        writefln(" clear()");
        auto s = new UniqueList!int;
        s.add([2,4,3]);
        s.clear();
        assert(s.isEmpty());
        assert(s.length==0);
    }
    {
        writefln(" contains()");
        auto s = new UniqueList!int;
        s.add([2,4,3]);
        assert(s.contains(2));
        assert(s.contains(4));
        assert(s.contains(3));
        assert(!s.contains(1));
    }
}
