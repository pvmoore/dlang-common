module common.utils.async_utils;

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
            // ecx = add
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
    // https://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html

    /**
    * If [ptr] == expected then [ptr] = value else don't update.
    * Returns the old value.
    */
    uint cas32(void* ptr, uint expected, uint newValue) nothrow @nogc {
        // $0 eax            
        // $1 ptr            
        // $2 expected (eax) 
        // $3 newValue       
        return __asm!uint(`
            lock
            cmpxchg $3, ($1)
            `,
            "={eax},r,{eax},r",
            ptr, expected, newValue);
    }
    ulong cas64(void* ptr, ulong expected, ulong newValue) nothrow @nogc {
        // $0 rax            
        // $1 ptr            
        // $2 expected (rax) 
        // $3 newValue       
        return __asm!ulong(`
            lock
            cmpxchg $3, ($1)
            `,
            "={rax},r,{rax},r",
            ptr, expected, newValue);
    }
    uint atomicSet32(void* ptr, uint newValue) nothrow @nogc {
        // $0 return
        // $1 ptr
        // $2 newValue
        return __asm!uint(`
            xchg $2, ($1)
            mov $2, $0
            `,
            "=r,r,r",
            ptr, newValue
        );
    }
    /* The should be enough on x86 arch */
    uint atomicGet32(void* ptr) nothrow @nogc {
        // $0 return
        // $1 ptr
        return __asm!uint(`
            mov ($1), $0
            `,
            "=r,r", ptr);
    }
    void atomicAdd32(void* ptr, uint add) nothrow @nogc {
        // $0 ptr
        // $1 add
        __asm(`
            lock
            xaddl $1, $0
            `,
            "=*m,r", ptr, add);
    }
    ulong atomicSet64(void* ptr, ulong newValue) nothrow @nogc {
        // $0 return 
        // $1 ptr
        // $2 newValue
        return __asm!ulong(`
            xchg $2, ($1)
            mov $2, $0
            `,
            "=r,r,r",
            ptr, newValue
        );
    }
    /* The should be enough on x86 arch */
    ulong atomicGet64(void* ptr) nothrow @nogc {
        // $0 return
        // $1 ptr
        return __asm!ulong(`
            movq ($1), $0
            `,
            "=r,r", ptr);
    }
    void atomicAdd64(void* ptr, ulong add) nothrow @nogc {
        // $0 ptr
        // $1 add
        __asm(`
            lock
            xaddq $1, $0
            `,
            "=*m,r", ptr, add);
    }
    void mfence() nothrow @nogc {
        __asm(`mfence`, "");
    }
    void lfence() nothrow @nogc {
        __asm(`lfence`, "");
    }
    void sfence() nothrow @nogc {
        __asm(`sfence`, "");
    }

} // LDC

bool atomicIsTrue(ref bool b) {
    return atomicLoad(b);
}
void atomicSet(ref bool b, bool value) {
    atomicStore(b, value);
}
