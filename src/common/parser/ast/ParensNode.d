module common.parser.ast.ParensNode;

import common.all;
import common.parser;

/**
 * ParensNode
 *      EPNode
 */
final class ParensNode(T) : EPNode!T {

    override T eval() {
        return first().eval();
    }
    override string toString() {
        return "Parens";
    }
}