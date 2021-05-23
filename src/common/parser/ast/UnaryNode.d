module common.parser.ast.UnaryNode;

import common.all;
import common.parser;

/**
 *  UnaryNode
 *      EPNode
 */
final class UnaryNode(T) : EPNode!T {
    Operator op;

    this(Operator op) {
        this.op = op;
    }
    override T eval() {
        auto left = first().eval();

        final switch(op) with(Operator) {
            case ADD:
            case SUB:
            case MUL:
            case DIV:
            case MOD:
            case BITAND:
            case BITXOR:
            case BITOR:
                throw new Exception("Shouldn't get here");
            case NEG:
                return -left;
        }
    }
    override int precedence() {
        return op.getPrecedence();
    }
    override string toString() {
        return "Unary(%s)".format(op);
    }
}