module common.parser.ast.NumberNode;

import common.all;
import common.parser;

final class NumberNode(T) : EPNode!T {
    T value;

    this(T value) {
        this.value = value;
    }
    override T eval() {
        return value;
    }
    override string toString() {
        return "Number(%s)".format(value);
    }
}