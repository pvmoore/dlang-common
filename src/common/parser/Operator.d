module common.parser.Operator;

enum Operator {
    ADD,
    SUB,
    MUL,
    DIV,
    MOD
}

int getPrecedence(Operator op) {
    final switch(op) with(Operator) {
        case ADD:
        case SUB:
            return 10;
        case MUL:
        case DIV:
        case MOD:
            return 5;
    }
}