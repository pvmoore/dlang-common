module common.parser.Operator;

enum Operator {
    ADD,
    SUB,
    MUL,
    DIV,
    MOD,
    BITAND,
    BITOR,
    BITXOR,

    NEG
}

int getPrecedence(Operator op) {
    final switch(op) with(Operator) {
        case BITOR:
            return 20;
        case BITXOR:
            return 17;
        case BITAND:
            return 15;
        case ADD:
        case SUB:
            return 10;
        case MUL:
        case DIV:
        case MOD:
            return 5;
        case NEG:
            return 3;
    }
}