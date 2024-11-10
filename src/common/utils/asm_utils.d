module common.utils.asm_utils;

import std.stdio : writefln;

/**
 * Win64 calling convention:
 * https://docs.microsoft.com/en-us/cpp/build/x64-calling-convention
 *
 * Function arguments:
 * DMD: (Arguments are passed in opposite order to the Win64 ABI)
 *  [1 param]    RCX|XMM0
 *  [2 params]   RDX|XMM1,  RCX|XMM0
 *  [3 params]    R8|XMM2,  RDX|XMM1, RCX|XMM0
 *  [4 params]    R9|XMM3,   R8|XMM2, RDX|XMM1, RCX|XMM0
 *  [5 params] stack|stack,  R9|XMM3,  R8|XMM2, RDX|XMM1, RCX|XMM0
 *
 * LDC: (Arguments are passed in Win64 ABI order. XMM4 and XMM5 are also used if required)
 *      RCX|XMM0, RDX|XMM1, R8|XMM2, R9|XMM3, stack|XMM4, stack|XMM5, stack|stack
 *
 * Return value:
 *      RAX (integer)
 *      XMM0 (float,double)
 *
 * Clobbered:
 *      RAX, RCX, RDX, R8, R9, R10, R11, XMM0-5, and the upper portions of YMM0-15 and ZMM0-15
 *      On AVX512VL: the ZMM, YMM, and XMM registers 16-31
 */

private:

version(DigitalMars) {
    /** 
     * Note this is the opposite order of the Win64 ABI)
     * xmm0 = d
     * xmm1 = c
     * xmm2 = b
     * xmm3 = a
     * Extra parameters are on the stack starting from param 0 
     */
    float testFloatParameters(float a, float b, float c, float d) {
        asm pure nothrow @nogc {
            naked;
            addss XMM0, XMM3;
            addss XMM0, XMM2;
            addss XMM0, XMM1;
            ret;
        }
    }
    /**
     * Note this is the opposite order of the Win64 ABI)
     * rcx = d
     * rdx = c
     * r8  = b
     * r9  = a
     * Extra parameters are on the stack starting from param 0 
     */
    ulong testLongParameters(ulong a, ulong b, ulong c, ulong d) {
        asm pure nothrow @nogc {
            naked;
            mov RAX, RCX;
            add RAX, RDX;
            add RAX, R8;
            add RAX, R9;
            ret;
        }
    }
    /**
     * Note this is the opposite order of the Win64 ABI)
     * rcx  = d
     * xmm1 = c
     * r8   = b
     * xmm3 = a
     * Extra parameters are on the stack starting from param 0 
     */
    float testMixedParameters(float a, ulong b, float c, ulong d) {
        asm pure nothrow @nogc {
            naked;
            cvtsi2ss XMM0, ECX;
            cvtsi2ss XMM2, R8D;
            addss XMM0, XMM1;
            addss XMM0, XMM2;
            addss XMM0, XMM3;
            ret;
        }
    }
} // version(DigitalMars)

version(LDC) {
    import ldc.llvmasm;
    import ldc.attributes;
    // https://wiki.dlang.org/LDC_inline_assembly_expressions
    // https://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html

    /**
     * Note that LDC actually uses the xmm4 and xmm5 clobbered regs as extra parameters 
     * xmm0 = a
     * xmm1 = b
     * xmm2 = c
     * xmm3 = d
     * xmm4 = e
     * xmm5 = f
     * Subsequent parameters are on the stack
     */
    float testFloatParameters(float a, float b, float c, float d, float e, float f) nothrow @nogc {
        return __asm!float(`
            addss %xmm5, %xmm0
            addss %xmm4, %xmm0
            addss %xmm3, %xmm0
            addss %xmm2, %xmm0
            addss %xmm1, %xmm0
            `,
            "={xmm0}," ~                                        // outputs
            "{xmm0}, {xmm1}, {xmm2}, {xmm3}, {xmm4}, {xmm5}",   // inputs
            a,b,c,d,e,f                                         // input values
        );
    }
    /**
     * rcx = a
     * rdx = b
     * r8  = c
     * r9  = d
     * Subsequent parameters are on the stack
     */
    ulong testLongParameters(ulong a, ulong b, ulong c, ulong d) nothrow @nogc {
        return __asm!ulong(`
            mov %rcx, %rax
            add %rdx, %rax
            add %r8, %rax
            add %r9, %rax
            `,
            "={rax}, {rcx}, {rdx}, {r8}, {r9}",
            a,b,c,d
        );
    }
    /**
     * xmm0 = a
     * rdx  = b
     * xmm2 = c
     * r9   = d
     * xmm4 = e
     * Subsequent parameters are on the stack 
     */
    float testMixedParameters(float a, ulong b, float c, ulong d, float e) nothrow @nogc @naked {
        return __asm!float(`
            cvtsi2ss %rdx, %xmm1
            cvtsi2ss %r9, %xmm3
            addss %xmm1, %xmm0
            addss %xmm2, %xmm0
            addss %xmm3, %xmm0
            addss %xmm4, %xmm0
            `,
            "={xmm0}"
        );
    }

    uint atomicSet32(void* ptr, uint newValue) nothrow @nogc @naked {
        // rcx = ptr
        // edx = newValue
        // Note: ret is implicitly added
        return __asm!uint(`
            xchg %edx, (%rcx)
            mov %edx, %eax
            `,
            "={eax}"
        );
    }
} // version(LDC)

version(DigitalMars) {

__gshared float f1,f2,f3,f4,f5,f6,f7,f8;

public:

/**
 *  128 bit AVX
 */
void dumpXMMfloat(int index) {
	asm pure nothrow {
		// rcx = index
		lea RDX, f1;

        dec ECX;
        jns _1;
        movups [RDX], XMM0;
        jmp _end;
_1:		dec ECX;
        jns _2;
        movups [RDX], XMM1;
        jmp _end;
_2:		dec ECX;
        jns _3;
        movups [RDX], XMM2;
        jmp _end;
_3:		dec ECX;
        jns _4;
        movups [RDX], XMM3;
        jmp _end;
_4:		dec ECX;
        jns _5;
        movups [RDX], XMM4;
        jmp _end;
_5:		dec ECX;
        jns _6;
        movups [RDX], XMM5;
        jmp _end;
_6:		dec ECX;
        jns _7;
        movups [RDX], XMM6;
        jmp _end;
_7:		dec ECX;
        jns _8;
        movups [RDX], XMM7;
        jmp _end;
_8:		dec ECX;
        jns _9;
        movups [RDX], XMM8;
        jmp _end;
_9:		dec ECX;
        jns _10;
        movups [RDX], XMM9;
        jmp _end;
_10:	dec ECX;
        jns _11;
        movups [RDX], XMM10;
        jmp _end;
_11:	dec ECX;
        jns _12;
        movups [RDX], XMM11;
        jmp _end;
_12:	dec ECX;
        jns _13;
        movups [RDX], XMM12;
        jmp _end;
_13:	dec ECX;
        jns _14;
        movups [RDX], XMM13;
        jmp _end;
_14:	dec ECX;
        jns _15;
        movups [RDX], XMM14;
        jmp _end;
_15:	dec ECX;
        jns _end;
        movups [RDX], XMM15;
_end:;
	}
   	writefln("[XMM%2s] %12s %12s %12s %12s", index, f1, f2, f3, f4);
}

/**
 *  256 bit AVX2
 */
void dumpYMMfloat(int index) {
	asm pure nothrow {
		// rcx = index
		lea RDX, f1;

        dec ECX;
        jns _1;
        vmovups [RDX], YMM0;
        jmp _end;
_1:		dec ECX;
        jns _2;
        vmovups [RDX], YMM1;
        jmp _end;
_2:		dec ECX;
        jns _3;
        vmovups [RDX], YMM2;
        jmp _end;
_3:		dec ECX;
        jns _4;
        vmovups [RDX], YMM3;
        jmp _end;
_4:		dec ECX;
        jns _5;
        vmovups [RDX], YMM4;
        jmp _end;
_5:		dec ECX;
        jns _6;
        vmovups [RDX], YMM5;
        jmp _end;
_6:		dec ECX;
        jns _7;
        vmovups [RDX], YMM6;
        jmp _end;
_7:		dec ECX;
        jns _8;
        vmovups [RDX], YMM7;
        jmp _end;
_8:		dec ECX;
        jns _9;
        vmovups [RDX], YMM8;
        jmp _end;
_9:		dec ECX;
        jns _10;
        vmovups [RDX], YMM9;
        jmp _end;
_10:	dec ECX;
        jns _11;
        vmovups [RDX], YMM10;
        jmp _end;
_11:	dec ECX;
        jns _12;
        vmovups [RDX], YMM11;
        jmp _end;
_12:	dec ECX;
        jns _13;
        vmovups [RDX], YMM12;
        jmp _end;
_13:	dec ECX;
        jns _14;
        vmovups [RDX], YMM13;
        jmp _end;
_14:	dec ECX;
        jns _15;
        vmovups [RDX], YMM14;
        jmp _end;
_15:	dec ECX;
        jns _end;
        vmovups [RDX], YMM15;
_end:;
	}
   	writefln("[YMM%2s] %12s %12s %12s %12s %12s %12s %12s %12s",
       index, f1, f2, f3, f4, f5, f6, f7, f8);
}

} // version(DigitalMars)
