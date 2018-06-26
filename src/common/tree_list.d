module common.tree_list;

import common.all;
/**
 *  T required opCmp and opEquals implementations.
 */
final class TreeList(T) {
    long length;
    Node root;

    private static final class Node {
        Node up;
        Node left;
        Node right;
        T value;
        int balance() const {
            return (left ? -1 + left.balance : 0) +
                   (right ? 1 + right.balance : 0);
        }
    }

    bool empty() const { return length==0; }

    override bool opEquals(Object other) {
        auto o = cast(TreeList!T)other;
        if(length!=o.length) return false;
        Node n  = first(root);
        Node n2 = first(o.root);
        while(n) {
            if(n.value != n2.value) return false;
            n  = next(n);
            n2 = next(n2);
        }
        return true;
    }
    bool opEquals(T[] array) {
        if(length!=array.length) return false;
        Node n  = first(root);
        long i  = 0;
        while(n) {
            if(n.value != array[i++]) return false;
            n  = next(n);
        }
        return true;
    }
    // discourage slicing
//    T[] opSlice() {
//        auto buf = appender!(T[]);
//        Node n = root;
//        while(n) {
//            buf ~= n.value;
//            n = next(n);
//        }
//        return buf.data;
//    }
//    T[] opSlice(long start, long end) {
//
//    }
//    long opDollar() { return length; }

    auto add(T value) {
        length++;
        auto nn = newNode(value);
        if(!root) {
            root = nn;
        } else {
            Node n      = root;
            Node parent = null;
            while(n) {
                parent = n;
                if(value <= n.value) {
                    n = n.left;
                    if(!n) parent.left = nn;
                } else {
                    n = n.right;
                    if(!n) parent.right = nn;
                }
            }
            nn.up = parent;
        }
        return this;
    }
    bool remove(T value) {
        writefln("remove(%s)", value);
        auto n = root;
        while(n) {
            writefln("n=%s", n.value);
            if(value==n.value) {
                detachNode(n);
                return true;
            }
            if(value < n.value) {
                n = n.left;
            } else {
                n = n.right;
            }
        }
        return false;
    }
    auto clear() {
        length  = 0;
        root = null;
        return this;
    }
    auto rebalance() {
        if(!root) return this;
        int b = root.balance;
        if(abs(b)<2) return this;
        // todo - rebalance the tree
        return this;
    }
    override string toString() {
        auto buf = appender!(T[]);
        Node n = first(root);
        while(n) {
            buf ~= n.value;
            n = next(n);
        }
        return "[TreeList length=%s balance=%s %s]".
            format(length,root?root.balance:0,buf.data);
    }
private:
    void detachNode(Node n) {
        writefln("detach node %s", n.value);
        auto left     = n.left;
        auto right    = n.right;
        auto up       = n.up;
        auto downlink = up ? up.left is n ? &up.left
                                          : &up.right
                           : null;

        if(!left && !right) {
            if(up) *downlink = null;
            else root = null;
        } else if(!left) {
            // move right upwards
            if(up) {
                *downlink = right;
            } else {
                root = right;
            }
            right.up = up;
        } else {
            // move left upwards
            if(up) {
                *downlink = left;
            } else {
                root = left;
            }
            left.up = up;
            if(right) {
                auto n2  = last(left);
                n2.right = right;
                right.up = n2;
            }
        }
    }
    static Node newNode(T value) {
        auto n = new Node();
        n.value = value;
        return n;
    }
    static Node first(Node n) {
        if(n) while(n.left) n = n.left;
        return n;
    }
    static Node last(Node n) {
        if(n) while(n.right) n = n.right;
        return n;
    }
    static Node prev(Node self) {
        Node r = last(self.left);
        if(r) return r;
        r = self;
        while(r.up) {
            if(r.up.right is r) {
                return r.up;
            }
            r = r.up;
        }
        return null;
    }
    static Node next(Node self) {
        Node r = first(self.right);
        if(r) return r;
        r = self;
        while(r.up) {
            if(r.up.left is r) {
                return r.up;
            }
            r = r.up;
        }
        return null;
    }
}

