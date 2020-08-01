module common.containers.List;

import common.all;

/**
 *  Single linked list
 */
final class List(T) {
private:
    Node head, tail;
    int len;

    static class Node {
        Node next;
        T value;
        this(Node next, T value) { this.next=next; this.value=value; }
    }
public:
    override string toString() {
        auto buf = appender!(string[]);
        Node n = head;
        while(n) {
            buf ~= "%s".format(n.value);
            n = n.next;
        }
        return "[" ~ buf.data.join(", ") ~ "]";
    }
nothrow:
    @property int length() const { return len; }
    @property bool empty() const { return length==0; }
    this() {

    }
    T opIndex(int i) {
        Node[2] n = find(i);
        return n[1] ? n[1].value : T.init;
    }
    void opIndexAssign(int i, T val) {
        Node[2] n = find(i);
        if(n[1]) {
            n[1].value = val;
        }
    }
    override size_t toHash() nothrow {
        import core.internal.hash : hashOf;
        if(len==0) return 0;
        auto ptr = head;
        ulong a = 5381;
        for(auto i=0; i<len; i+=4) {
            a  = (a << 7)  + hashOf!T(ptr.value); ptr = ptr.next;
            a ^= (a << 13) + hashOf!T(ptr.value); ptr = ptr.next;
            a  = (a << 19) + hashOf!T(ptr.value); ptr = ptr.next;
            a ^= (a << 23) + hashOf!T(ptr.value); ptr = ptr.next;
        }
        foreach(i; 0..len%3) {
            a  = (a << 7) + hashOf(ptr.value);
            ptr = ptr.next;
        }
        return a;
    }
    bool opEquals(T[] array) {
        if(len != array.length) return false;
        Node n = head;
        for(auto i=0; i<len; i++) {
            if(n.value != array[i]) return false;
            n = n.next;
        }
        return true;
    }
    bool opEquals(List!T l) {
        if(len != l.length) return false;
        int i   = len;
        Node n  = head;
        Node n2 = l.head;
        while(i) {
            if(n.value != n2.value) return false;
            n = n.next;
            n2 = n2.next;
            i--;
        }
        return true;
    }
    auto add(T value) {
        if(!head) {
            head = tail = new Node(null, value);
        } else {
            Node n = new Node(null, value);
            tail.next = n;
            tail = n;
        }
        len++;
        return this;
    }
    T remove(int index) {
        Node[2] n = find(index);
        T value = n[1].value;

        Node prev = n[0];
        Node next = n[1].next;
        if(!next) tail = prev;

        if(prev) {
            prev.next = next;
        } else {
            head = next;
        }

        len--;
        return value;
    }
    auto insert(T value, int index) {
        if(index==len) {
            return add(value);
        }
        Node[2] n    = find(index);
        Node newnode = new Node(n[1], value);

        if(n[0]) {
            n[0].next = newnode;
        } else {
            head = newnode;
        }

        len++;
        return this;
    }
    auto clear() {
        len = 0;
        head = tail = null;
        return this;
    }
private:
    /// Node[0] = node@array-1, Node[1] = node@array
    Node[2] find(int index) {
        if(index>=length) return [null,null];
        Node n    = head;
        Node prev = null;
        while(index > 0) {
            prev = n;
            n    = n.next;
            index--;
        }
        return [prev, n];
    }
}

