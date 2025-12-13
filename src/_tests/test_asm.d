module _tests.test_asm;

import std.stdio    : writefln;
import std.random   : uniform, uniform01, Mt19937;
import std.datetime.stopwatch : StopWatch, AutoStart;
import common.utils : as, throwIfNot;

void testAsm() {
    writefln("========--\nTesting asm\n==--");

    rng.seed(19);

    version(LDC) {
        {
            string a = "";
            string b = "";
            assert(memnspn(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 0);
            assert(memnspn_asm1(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 0);
        }
        {
            string a = "a";
            string b = "b"; 
            assert(memnspn(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 0);
            assert(memnspn_asm1(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 0);
        }
        {
            string a = "aa";
            string b = "ab"; 
            assert(memnspn(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 1);
            assert(memnspn_asm1(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 1);
        }
        {
            string a = "aac";
            string b = "aaa"; 
            assert(memnspn(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 2);
            assert(memnspn_asm1(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 2);
        }
        {
            string a = "hello there1";
            string b = "hello there2";
            assert(memnspn(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 11);
            assert(memnspn_asm1(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 11);
        }
        {
            string a = "hello There";
            string b = "hello there";
            assert(memnspn(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 6);
            assert(memnspn_asm1(a.ptr.as!(ubyte*), b.ptr.as!(ubyte*), a.length) == 6);
        }
    }
    uint result;

    string original = createRandomString(100);
    string[] strings;

    foreach(i; 0..100) {
        strings ~= createMutatedCopy(original, 0.01f);
        //writefln("%s %s", strings[i], memnspn(strings[i].ptr.as!(ubyte*), original.ptr.as!(ubyte*), original.length));
    }

    StopWatch w = StopWatch(AutoStart.yes);
    foreach(i; 0..10000) {
        foreach(s; strings) {

            // 51ms
            result += memnspn_asm1(s.ptr.as!(ubyte*), original.ptr.as!(ubyte*), original.length);

            // 27ms
            //result += memnspn(s.ptr.as!(ubyte*), original.ptr.as!(ubyte*), original.length);
        }
    }
    w.stop();

    writefln("result = %s", result);
    writefln("Took %s millis", w.peek().total!"nsecs"/1000000.0);
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private: 

version(LDC) {
    import ldc.llvmasm;
    import ldc.attributes;
} 

__gshared Mt19937 rng;

string createRandomString(uint length) {
    string s;
    foreach(i; 0..length) {
        s ~= 'a' + uniform(0, 26, rng);
    }
    return s;
}
string createMutatedCopy(string original, float mutationChance01) {
    char[] copy = original.dup;
    foreach(i; 0..original.length) {
        if(uniform01(rng) < mutationChance01) {
            copy[i] = ('a' + uniform(0, 26, rng)).as!char;
        } 
    }
    return copy.as!string;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────

/** Compare two strings and return the number of characters that match */ 
pragma(inline, false)
ulong memnspn(ubyte* str1, ubyte* str2, ulong count) {
    ulong i;
    for(i=0; i<count; i++) {
        if(str1[i] != str2[i]) break;
    }
    return i;
}
/** Optimised version of memnspn using asm */
pragma(inline, false)
ulong memnspn_asm1(ubyte* str1, ubyte* str2, ulong count) nothrow @nogc /*@naked*/ {
    version(LDC) {
        version(Win64) {
            // rcx, rdx, r8
            return __asm!ulong(`
                xor %rax, %rax

                // Exit if count == 0
                test %rcx, %rcx
                jz 1f

                // Compare bytes until we find a mismatch
                repe cmpsb
                jz 0f
                inc %rcx
0:
                sub %rcx, %r8
                mov %r8, %rax
1:              
                `, 
                "={rax},{rsi},{rdi},{rcx},~{rsi},~{rdi},~{rcx},~{r8},~{flags}", 
                str1, str2, count);

                // a = al/ah/ax/eax/rax
                // r = register operand
                // q = register that can be accessed as 8bit low (eg AL)
                // Q = register that can be accessed as 16bit high (eg AH)
                // y = 64bit mmx register
                // v = xmm|ymm register
                // i = immediate integer operand
                // m = memory operand
                // * = indirect memory operand (eg *m)
                // I = integer constant [0..31]
                // J = integer constant [0..63]
                // O = integer constant [0..127]
                // K = integer constant [0..255]
                // N = unsigned integer constant [0..255]
                // e = signed 32bit integer constant
                // Z = unsigned 32bit integer constant 
                // =& = early clobber (eg =&r)

                // = output modifier
                // + input/output modifier
                // ~ clobber modifier
        } 
    } 
    return 0;
}
