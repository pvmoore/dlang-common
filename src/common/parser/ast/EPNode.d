module common.parser.ast.EPNode;

import common.all;
import common.parser;

abstract class EPNode(T) {
    EPNode parent;
    EPNode[] children;

    EPNode first() {
        expect(children.length>0);
        return children[0];
    }
    EPNode last() {
        expect(children.length>0);
        return children[$-1];
    }

    void add(EPNode n) {
        detach(n);
        children ~= n;
        n.parent = this;
    }
    void detach(EPNode n) {
        if(n.parent) {
            n.parent.children.removeAt(n.index());
            n.parent = null;
        }
    }
    int index() {
        expect(parent !is null);
        return parent.children.indexOf(this);
    }
    int precedence() { return 15; }

    abstract T eval();

    bool isResolved() {
        foreach(c; children) {
            if(!c.isResolved()) return false;
        }
        return true;
    }
    void resolve(T[string] references) {
        foreach(c; children) {
            c.resolve(references);
        }
    }

    string dump(string indent="") {
        string buf = "%s%s\n".format(indent, this);
        foreach(c; children) {
            buf ~= c.dump(indent ~ "  ");
        }
        return buf;
    }
}