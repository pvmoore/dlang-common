module test_betterc;

public:
extern(C):
@nogc:
nothrow:

int printf(immutable(char)* format, ...);

void testBetterc() {
    printf("\n================================\n");
    printf("Testing betterC...\n");
    printf("================================\n");

    import common.betterc;

    auto a = 10;
    auto b = a.as!float;
    assert(is(typeof(b)==float));


}