module common.parser.ast.BinaryNode;

import common.all;
import common.parser;

/**
 *  BinaryNode
 *      EPNode
 *      EPNode
 */
final class BinaryNode(T) : EPNode!T {
    Operator op;

    this(Operator op) {
        this.op = op;
    }
    override T eval() {
        auto left = first().eval();
        auto right = last().eval();

        final switch(op) with(Operator) {
            case ADD: return left + right;
            case SUB: return left - right;
            case MUL: return left * right;
            case DIV: return left / right;
            case MOD: return left % right;
            case NEG: throw new Exception("Shouldn't get here");
        }
    }
    override int precedence() {
        return op.getPrecedence();
    }
    override string toString() {
        return "Binary(%s)".format(op);
    }
}