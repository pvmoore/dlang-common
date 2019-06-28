module common.wasm.json;

public:
extern(C):
@nogc:
nothrow:

int printf(immutable(char)* format, ...);

void log(A...)(string fmt, A args) {
    static if(true) {
        try{
            printf(fmt.ptr, args);
        }catch(Exception e) {}
    }
}

// [{"index":0,"box":0,"value":0,"isIser":1,"scratch":{}},
struct JSON(OBSERVER) {
@nogc:
nothrow:
private:
    OBSERVER observer;
    string bytes;
    int len;
    int pos;
public:
    this(OBSERVER observer, string bytes) {
        this.observer = observer;
        this.bytes = bytes;
    }
    void parse() {
        log("parse %d '%c'\n", pos, peek());
        auto c = peek();
        if(c=='[') {
            array();
        } else if(c=='{') {
            object();
        } else if(c>='0' && c<='9') {
            number();
        } else {
            log("yahoo %c @ pos %d\n", c, pos);
            assert(false);
        }
    }
private:
    void array() {
        log("array start %d '%c'\n", pos, peek());
        // [
        observer.onArray(true);
        pos++;

        while(peek()!=']') {
            parse();

            if(peek()==',') pos++;
        }

        // ]
        observer.onArray(false);
        log("array end %d '%c'\n", pos, peek());
        pos++;
    }
    void object() {
        log("object start %d '%c'\n", pos, peek());
        // {
        observer.onObject(true);
        pos++;

        do{
            if(peek()==',') pos++;

            if(peek()=='\"') {
                key();
                parse();
            }
        }while(peek()==',');

        // }
        observer.onObject(false);
        log("object end %d '%c'\n", pos, peek());
        pos++;
    }
    void key() {
        log("key %d '%c'\n", pos, peek());
        // "
        pos++;

        int start = pos;
        int end = indexOf('\"');
        pos = end+1;

        observer.onKey(bytes[start..end]);
        log("     key=%d..%d '%c'\n", start, end, peek());

        // :
        pos++;
        log("value %d '%c'\n", pos, peek());
    }
    void number() {
        log("number %d '%c'\n", pos, peek());
        // 0..9

        int start = pos;
        while(peek()>='0' && peek()<='9') {
            pos++;
        }

        observer.onNumber(bytes[start..pos]);
        log("   number = %d..%d '%c'\n", start, pos, peek());
    }

    ubyte peek() {
        while(pos<bytes.length) {
            auto c = bytes[pos];
            if(c>32) return c;
            pos++;
        }
        return 0;
    }
    int indexOf(char ch) {
        for(auto i = pos; i<bytes.length; i++) {
            if(bytes[i]==ch) return i;
        }
        return -1;
    }
}


