module common.utils.async_utils;

import common.all;
import core.thread  : Thread, ThreadID;
import core.atomic  : atomicOp, atomicLoad, atomicStore, cas;

// struct AssertSingleThreaded {
// private:
//     shared ThreadID savedThreadId = ThreadID.init;
// public:
//     void check() {
//         version(assert) {
//             auto id     = Thread.getThis().id;
//             auto prevId = atomicLoad(savedThreadId);

//             if(prevId==ThreadID.init) {
//                 atomicStore(savedThreadId, id);
//             } else {
//                 assert(id == prevId, "Second thread detected in single threaded code");
//             }
//         }
//     }
// }

/**
 * Win64 calling convention:
 * https://docs.microsoft.com/en-us/cpp/build/x64-calling-convention?view=vs-2019
 *
 * LDC is using parameters in the opposite direction to the Win64 ABI:
 * eg. [1 param]  RCX
 *     [2 params] RDX, RCX
 *     [3 params] R8, RDX, RCX
 *     [4 params] R9, R8, RDX, RCX
 *     [5 params] stack, R9, R8, RDX, RCX
 *     [5 params] stack, XMM3, XMM2, XMM1, XMM0 (real args)
 *
 * Return value:
 *      RAX (integer)
 *      XMM0 (float,double)
 *
 * Clobbered:
 *      RAX, RCX, RDX, R8, R9, R10, R11, XMM0-5, and the upper portions of YMM0-15 and ZMM0-15
 *      On AVX512VL: the ZMM, YMM, and XMM registers 16-31
 */
version(DigitalMars) {
    /**
    * If [ptr] == expected then [ptr] = value else don't update.
    * Returns the old value.
    */
    uint cas32(void* ptr, uint expected, uint newValue) {
        asm pure nothrow @nogc {
            // r8 = ptr
            // edx = expected
            // ecx = newValue
            naked;
            mov EAX, EDX;
            lock; cmpxchg [R8], ECX;
            // return original value in EAX
            ret;
        }
    }
    /**
    * If [ptr] == expected then [ptr] = value else don't update.
    * Returns the old value.
    */
    ulong cas64(void* ptr, ulong expected, ulong newValue) {
        asm pure nothrow @nogc {
            // r8 = ptr
            // rdx = expected
            // rcx  = newValue
            naked;
            mov RAX, RDX;
            lock; cmpxchg [R8], RCX;
            // return original value in RAX
            ret;
        }
    }
    /**
    * Set newValue at [ptr].
    * Returns the old value.
    */
    uint atomicSet32(void* ptr, uint newValue) {
        asm pure nothrow @nogc {
            // rdx = ptr
            // rcx = newValue
            naked;

            //mov [RCX], EDX;
            //mfence;

            xchg [RDX], ECX;    // implicit lock
            mov EAX, ECX;
            ret;
        }
    }
    uint atomicGet32(void* ptr) {
        asm pure nothrow @nogc {
            // rcx = ptr
            naked;
            mov EAX, [RCX];
            ret;
        }
    }
    void atomicAdd32(void* ptr, uint add) {
        asm pure nothrow @nogc {
            // rdx = ptr
            // rcx = add
            naked;
            lock; xadd [RDX], ECX;
            ret;
        }
    }
    /**
    * Set newValue at [ptr].
    * Returns the old value.
    */
    ulong atomicSet64(void* ptr, ulong newValue) {
        asm pure nothrow @nogc {
            // rdx = ptr
            // rcx = newValue
            naked;

            //mov [RCX], RDX;
            //mfence;

            xchg [RDX], RCX;    // implicit lock
            mov RAX, RCX;
            ret;
        }
    }
    /* This should be enough on x86 arch */
    ulong atomicGet64(void* ptr) {
        asm pure nothrow @nogc {
            // rcx = ptr
            naked;
            mov RAX, [RCX];
            ret;
        }
    }
    void atomicAdd64(void* ptr, ulong add) {
        asm pure nothrow @nogc {
            // rdx = ptr
            // rcx = add
            naked;
            lock; xadd [RDX], RCX;
            ret;
        }
    }
    void mfence() {
        asm pure nothrow @nogc { naked; mfence; ret; }
    }
    void lfence() {
        asm pure nothrow @nogc { naked; lfence; ret; }
    }
    void sfence() {
        asm pure nothrow @nogc { naked; sfence; ret; }
    }
} // DigitalMars
version(LDC) {
    import ldc.llvmasm;
    import ldc.attributes;
    // See https://wiki.dlang.org/LDC_inline_assembly_expressions

    /**
    * If [ptr] == expected then [ptr] = value else don't update.
    * Returns the old value.
    */
    uint cas32(void* ptr, uint expected, uint newValue) nothrow @nogc @naked {
        // r8 = ptr
        // edx = expected
        // ecx = newValue
        return __asm!uint(`
            mov %edx, %eax
            lock
            cmpxchg %ecx, (%r8)
            `,
            "={eax}");
    }
    ulong cas64(void* ptr, ulong expected, ulong newValue) nothrow @nogc @naked {
        // r8 = ptr
        // rdx = expected
        // rcx = newValue
        return __asm!uint(`
            mov %rdx, %rax
            lock
            cmpxchg %rcx, (%r8)
            `,
            "={rax}");
    }
    uint atomicSet32(void* ptr, uint newValue) nothrow @nogc @naked {
        // rdx = ptr
        // rcx = newValue
        // Note: ret is implicitly added
        return __asm!uint(`
            xchg %ecx, (%rdx)
            mov %ecx, %eax
            `,
            "={eax}"
        );
    }
    /* The should be enough on x86 arch */
    uint atomicGet32(void* ptr) nothrow @nogc @naked {
        // rcx = ptr
        return __asm!uint(`
            mov (%rcx), %eax
            `,
            "={eax}");
    }
    void atomicAdd32(void* ptr, uint add) nothrow @nogc @naked {
        // rdx = ptr
        // ecx = add
        // Note: ret needs to be added manually
        __asm(`
            lock
            xadd %ecx, (%rdx)
            ret
            `,
            "");
    }

    ulong atomicSet64(void* ptr, ulong newValue) nothrow @nogc @naked {
        // rdx = ptr
        // rcx = newValue
        // Note: ret is implicitly added
        return __asm!ulong(`
            xchg %rcx, (%rdx)
            mov %rcx, %rax
            `,
            "={rax}"
        );
    }
    /* The should be enough on x86 arch */
    ulong atomicGet64(void* ptr) nothrow @nogc @naked {
        // rcx = ptr
        return __asm!ulong(`
            mov (%rcx), %rax
            `,
            "={rax}");
    }
    void atomicAdd64(void* ptr, ulong add) nothrow @nogc @naked {
        // rdx = ptr
        // rcx = add
        // Note: ret needs to be added manually
        __asm(`
            lock
            xadd %rcx, (%rdx)
            ret
            `,
            "");
    }
    void mfence() nothrow @nogc @naked {
        __asm(`mfence; ret`, "");
    }
    void lfence() nothrow @nogc @naked {
        __asm(`lfence; ret`, "");
    }
    void sfence() nothrow @nogc @naked {
        __asm(`sfence; ret`, "");
    }

} // LDC
