module common.intrinsics;

import common.all;

version(LDC) {
    import ldc.intrinsics : llvm_expect;
    pragma(inline,true):
    bool likely(bool b) pure nothrow @nogc {
        return llvm_expect(b, true);
    }
    bool unlikely(bool b) pure nothrow @nogc {
        return llvm_expect(b, false);
    }
} else {
    pragma(inline,true):
    bool likely(bool b) pure nothrow @nogc {
        return b;
    }
    bool unlikely(bool b) pure nothrow @nogc {
        return b;
    }
}

