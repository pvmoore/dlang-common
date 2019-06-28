module test_wasm;

public:
import std.stdio;
import common.wasm;

extern(C):
@nogc:
nothrow:

int printf(immutable(char)* format, ...);

void testWasm() {
    printf("\n================================\n");
    printf("Testing wasm...\n");
    printf("================================\n");

    //              3      10      18        28         39          51
    //              |      |       |         |          |           |
    //              |      |       |         |          |           |
    string s1 = `[{"index":0,"box":0,"value":0,"isIser":1,"scratch":{}},
                 {"index":1,"box":0,"value":2,"isIser":0,"scratch":{}},{"index":2,"box":0,"value":8,"isIser":0,"scratch":{}},{"index":3,"box":1,"value":0,"isIser":1,"scratch":{}},{"index":4,"box":1,"value":7,"isIser":0,"scratch":{}},{"index":5,"box":1,"value":0,"isIser":1,"scratch":{}},{"index":6,"box":2,"value":0,"isIser":1,"scratch":{}},{"index":7,"box":2,"value":3,"isIser":0,"scratch":{}},{"index":8,"box":2,"value":1,"isIser":0,"scratch":{}},{"index":9,"box":0,"value":0,"isIser":1,"scratch":{}},{"index":10,"box":0,"value":0,"isIser":1,"scratch":{}},{"index":11,"box":0,"value":7,"isIser":0,"scratch":{}},{"index":12,"box":1,"value":0,"isIser":1,"scratch":{}},{"index":13,"box":1,"value":0,"isIser":1,"scratch":{}},{"index":14,"box":1,"value":5,"isIser":0,"scratch":{}},{"index":15,"box":2,"value":8,"isIser":0,"scratch":{}},{"index":16,"box":2,"value":0,"isIser":1,"scratch":{}},{"index":17,"box":2,"value":0,"isIser":1,"scratch":{}},{"index":18,"box":0,"value":6,"isIser":0,"scratch":{}},{"index":19,"box":0,"value":0,"isIser":1,"scratch":{}},{"index":20,"box":0,"value":0,"isIser":1,"scratch":{}},{"index":21,"box":1,"value":2,"isIser":0,"scratch":{}},{"index":22,"box":1,"value":0,"isIser":1,"scratch":{}},{"index":23,"box":1,"value":0,"isIser":1,"scratch":{}},{"index":24,"box":2,"value":0,"isIser":1,"scratch":{}},{"index":25,"box":2,"value":0,"isIser":1,"scratch":{}},{"index":26,"box":2,"value":0,"isIser":1,"scratch":{}},{"index":27,"box":3,"value":0,"isIser":1,"scratch":{}},{"index":28,"box":3,"value":0,"isIser":1,"scratch":{}},{"index":29,"box":3,"value":0,"isIser":1,"scratch":{}},{"index":30,"box":4,"value":1,"isIser":0,"scratch":{}},{"index":31,"box":4,"value":0,"isIser":1,"scratch":{}},{"index":32,"box":4,"value":7,"isIser":0,"scratch":{}},{"index":33,"box":5,"value":0,"isIser":1,"scratch":{}},{"index":34,"box":5,"value":0,"isIser":1,"scratch":{}},{"index":35,"box":5,"value":5,"isIser":0,"scratch":{}},{"index":36,"box":3,"value":0,"isIser":1,"scratch":{}},{"index":37,"box":3,"value":1,"isIser":0,"scratch":{}},{"index":38,"box":3,"value":2,"isIser":0,"scratch":{}},{"index":39,"box":4,"value":0,"isIser":1,"scratch":{}},{"index":40,"box":4,"value":0,"isIser":1,"scratch":{}},{"index":41,"box":4,"value":0,"isIser":1,"scratch":{}},{"index":42,"box":5,"value":9,"isIser":0,"scratch":{}},{"index":43,"box":5,"value":7,"isIser":0,"scratch":{}},{"index":44,"box":5,"value":0,"isIser":1,"scratch":{}},{"index":45,"box":3,"value":7,"isIser":0,"scratch":{}},{"index":46,"box":3,"value":0,"isIser":1,"scratch":{}},{"index":47,"box":3,"value":0,"isIser":1,"scratch":{}},{"index":48,"box":4,"value":4,"isIser":0,"scratch":{}},{"index":49,"box":4,"value":0,"isIser":1,"scratch":{}},{"index":50,"box":4,"value":3,"isIser":0,"scratch":{}},{"index":51,"box":5,"value":0,"isIser":1,"scratch":{}},{"index":52,"box":5,"value":0,"isIser":1,"scratch":{}},{"index":53,"box":5,"value":0,"isIser":1,"scratch":{}},{"index":54,"box":6,"value":0,"isIser":1,"scratch":{}},{"index":55,"box":6,"value":0,"isIser":1,"scratch":{}},{"index":56,"box":6,"value":0,"isIser":1,"scratch":{}},{"index":57,"box":7,"value":0,"isIser":1,"scratch":{}},{"index":58,"box":7,"value":0,"isIser":1,"scratch":{}},{"index":59,"box":7,"value":2,"isIser":0,"scratch":{}},{"index":60,"box":8,"value":0,"isIser":1,"scratch":{}},{"index":61,"box":8,"value":0,"isIser":1,"scratch":{}},{"index":62,"box":8,"value":6,"isIser":0,"scratch":{}},{"index":63,"box":6,"value":0,"isIser":1,"scratch":{}},{"index":64,"box":6,"value":0,"isIser":1,"scratch":{}},{"index":65,"box":6,"value":4,"isIser":0,"scratch":{}},{"index":66,"box":7,"value":5,"isIser":0,"scratch":{}},{"index":67,"box":7,"value":0,"isIser":1,"scratch":{}},{"index":68,"box":7,"value":0,"isIser":1,"scratch":{}},{"index":69,"box":8,"value":7,"isIser":0,"scratch":{}},{"index":70,"box":8,"value":0,"isIser":1,"scratch":{}},{"index":71,"box":8,"value":0,"isIser":1,"scratch":{}},{"index":72,"box":6,"value":5,"isIser":0,"scratch":{}},{"index":73,"box":6,"value":3,"isIser":0,"scratch":{}},{"index":74,"box":6,"value":0,"isIser":1,"scratch":{}},{"index":75,"box":7,"value":0,"isIser":1,"scratch":{}},{"index":76,"box":7,"value":6,"isIser":0,"scratch":{}},{"index":77,"box":7,"value":0,"isIser":1,"scratch":{}},{"index":78,"box":8,"value":2,"isIser":0,"scratch":{}},{"index":79,"box":8,"value":4,"isIser":0,"scratch":{}},{"index":80,"box":8,"value":0,"isIser":1,"scratch":{}}]`;

    string s2 = `[{"index":0,"box":0,"value":0,"isIser":1,"scratch":[1,2,3]}]`;

    struct Observer {
        @nogc:
        nothrow:
        void onArray(bool start) {

        }
        void onObject(bool start) {

        }
        void onKey(string key) {

        }
        void onNumber(string number) {

        }
    }
    Observer o;

    JSON!Observer(o, s2).parse();
}