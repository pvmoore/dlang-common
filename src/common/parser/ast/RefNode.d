module common.parser.ast.RefNode;

import common.all;
import common.containers;
import common.parser;

final class RefNode(T) : EPNode!T {
    string refName;
    T value;
    bool resolved;

    this(string refName) {
        this.refName = refName;
    }

    override T eval() {
        expect(resolved);
        return value;
    }
    override bool isResolved() {
        return resolved;
    }
    override bool containsMutableRef(Set!string mutableRefs) {
        return mutableRefs.contains(refName);
    }
    override void resolve(T[string] references) {
        auto p = refName in references;
        if(p) {
            value = *p;
            resolved = true;
        }
    }

    override string toString() {
        return "Ref(%s)".format(refName);
    }
}
