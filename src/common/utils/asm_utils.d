module common.utils.asm_utils;

import std.stdio                 : writefln;
import std.format                : format;
import std.conv                  : to;
import common.utils.utilities    : as;
import common.utils.string_utils : repeat;

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
version(LDC) {
    // https://wiki.dlang.org/LDC_inline_assembly_expressions
    // https://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html
    import ldc.llvmasm;
    import ldc.attributes;

    void setYMM(uint INDEX)(ref byte[32] values) nothrow @nogc {
        enum str = "vmovdqa $0, %ymm" ~ to!(char[])(INDEX);
        __asm(str, "*m", values.ptr); 
    }
    void setYMM(uint INDEX)(ref short[16] values) nothrow @nogc {
        enum str = "vmovdqa $0, %ymm" ~ to!(char[])(INDEX);
        __asm(str, "*m", values.ptr); 
    }
    void setYMM(uint INDEX)(ref int[8] values) nothrow @nogc {
        enum str = "vmovdqa $0, %ymm" ~ to!(char[])(INDEX);
        __asm(str, "*m", values.ptr); 
    }    
    void setYMM(uint INDEX)(ref long[4] values) nothrow @nogc {
        enum str = "vmovdqa $0, %ymm" ~ to!(char[])(INDEX);
        __asm(str, "*m", values.ptr); 
    }     
    void setYMM(uint INDEX)(ref float[8] values) nothrow @nogc {
        enum str = "vmovaps $0, %ymm" ~ to!(char[])(INDEX);
        __asm(str, "*m", values.ptr); 
    }    
    void setYMM(uint INDEX)(ref double[4] values) nothrow @nogc {
        enum str = "vmovapd $0, %ymm" ~ to!(char[])(INDEX);
        __asm(str, "*m", values.ptr); 
    }
    void getYMM(T, uint INDEX)(ref T[32/T.sizeof] dest) nothrow @nogc {
        enum instr = is(T==double) ? "vmovapd" : is(T==float) ? "vmovaps" : "vmovdqa";
        enum code = "%s %%ymm%s, $0".format(instr, INDEX);
        mixin("__asm(`%s`, \"*m\", dest.ptr);".format(code));  
    }
    void dumpYMM(T,uint INDEX)() { 
        align(32) T[32/T.sizeof] ymm;
        enum instr = is(T==double) ? "vmovapd" : is(T==float) ? "vmovaps" : "vmovdqa";
        enum code = "%s %%ymm%s, $0".format(instr, INDEX);
        mixin("__asm(`%s`, \"*m\", ymm.ptr);".format(code));   

        static if(is(T==ulong) || is(T==long)) {
            writefln("i64   [255         192] [191        128] [127         64] [63            0]"); 
            writefln("ymm%s: [%016x %016x %016x %016x]", INDEX, ymm[3], ymm[2], ymm[1], ymm[0]); 
        } else static if(is(T==uint) || is(T==int)) {
            writefln("i32   [    224] [   192] [   160] [   128] [    96] [    64] [    32] [      0]"); 
            writefln("ymm%s: [%08x %08x %08x %08x %08x %08x %08x %08x]", INDEX, ymm[7], ymm[6], ymm[5], ymm[4], ymm[3], ymm[2], ymm[1], ymm[0]);     
        } else static if(is(T==ushort) || is(T==short)) {
            writefln("i16   [ 15] [14] [13] [12] [11] [10] [ 9] [ 8] [ 7] [ 6] [ 5] [ 4] [ 3] [ 2] [ 1] [  0]"); 
            writefln("ymm%s: [%04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %04x]", INDEX, 
                ymm[15], ymm[14], ymm[13], ymm[12], ymm[11], ymm[10], ymm[9], ymm[8],
                ymm[7], ymm[6], ymm[5], ymm[4], ymm[3], ymm[2], ymm[1], ymm[0]);     
        } else static if(is(T==ubyte) || is(T==byte)) {
            writefln("i8     31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0]"); 
            writefln("ymm%s: [%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x " ~
                             "%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x]", INDEX, 
                             ymm[31], ymm[30], ymm[29], ymm[28], ymm[27], ymm[26], ymm[25], ymm[24],
                             ymm[23], ymm[22], ymm[21], ymm[20], ymm[19], ymm[18], ymm[17], ymm[16],
                             ymm[15], ymm[14], ymm[13], ymm[12], ymm[11], ymm[10], ymm[9], ymm[8],
                             ymm[7], ymm[6], ymm[5], ymm[4], ymm[3], ymm[2], ymm[1], ymm[0]);     
        } else static if(is(T==float) || is(T==double)) {
            enum M = 32/T.sizeof;    
            enum FMT = M == 8 ? "%.5f" : "%.8f";
            enum NAME = M == 8 ? "f32" : "f64";
            string hdr;
            string val;
            foreach_reverse(i; 0..M) {
                string s = FMT.format(ymm[i]);
                hdr ~= "[%s%s] ".format(repeat(" ", s.length - 3), i); 
                val ~= s ~ " ";
            }    
            writefln("%s   %s", NAME, hdr);
            writefln("ymm%s: %s", INDEX, val);
        } else static assert(false);
    }
    uint rol(uint value, uint cl) nothrow @nogc {
        return __asm!uint(`roll %cl, $0`, "={eax},{eax},{ecx}", value, cl);
    }
    uint ror(uint value, uint cl) nothrow @nogc {
        return __asm!uint(`rorl %cl, $0`, "={eax},{eax},{ecx}", value, cl);
    }

    /**
     * BMI1 instructions (Haswell and later):
     *   - andn
     *   - bextr 
     *   - blsi
     *   - blsmsk
     *   - blsr
     *   - tzcnt
     */ 
    ulong bextr(ulong src, ulong start, ulong len) nothrow @nogc {
        return __asm!ulong(`bextrq $2, $1, $0`, "=r,r,r", src, start | (len << 8));
    } 
    ulong bextr(ulong* src, ulong start, ulong len) nothrow @nogc {
        // bextr src:m64, startlen:r64 dest:r64
        return __asm!ulong(`bextrq $2, $1, $0`, "=r,*m,r", src, start | (len << 8));
    } 

    /**
     * BMI2 instructions (Haswell and later):
     *   - bzhi 
     *   - mulx
     *   - pdep Parallel bits deposit
     *   - pext Parallel bits extract
     *   - rorx
     *   - sarx
     *   - shrx
     *   - shlx
     */
    ulong pext(ulong src, ulong mask) nothrow @nogc {
        // pext mask:r64, src:r64, dest:r64
        return __asm!ulong(`pextq $1, $2, $0`, "=r,r,r", mask, src);
    } 
    ulong pext(ulong src, ulong* mask) nothrow @nogc {
        // pext mask:m64, src:r64, dest:r64
        return __asm!ulong(`pextq $1, $2, $0`, "=r,*m,r", mask, src);
    } 
    ulong pdep(ulong src, ulong mask) {
        return __asm!ulong(`pdepq $1, $2, $0`, "=r,r,r", mask, src);
    }
    ulong pdep(ulong src, ulong* mask) {
        return __asm!ulong(`pdepq $1, $2, $0`, "=r,*m,r", mask, src);
    }
    /** 
     * AVX2 instructions (Haswell and later): !!Subset
     *   - vbroadcast[ss|sd|f128]
     *   - vpbroadcast[b|w|d|q|i128]
     *   - vinsert[f128|i128]
     *   - vextract[f128|i128]
     *   - vgather[dpd|qpd|dps|qps]
     *   - vpgather[dd|dq|qd|qq]
     *   - vmaskmov[ps|pd]
     *   - vpmaskmov[d|q]
     *   - vperm[ps|d|pd|q]
     *   - vpermil[ps|pd]
     *   - vperm2f128
     *   - vpblend[d]
     *   - vpsllv[d|q]
     *   - vpsrlv[q|q]
     *   - vpsrav[d]
     *   - vtest[ps|pd]
     *   - vzeroall
     *   - vzeroupper
     */

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:
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
    // Example: Copy 64 bytes from src to dest
    void copy(void* dest, void* src) nothrow @nogc {
        __asm(`
        vmovaps (%rdx), %ymm0
        vmovaps %ymm0, (%rcx)
        addq $2, %rdx
        addq $2, %rcx
        vmovaps (%rdx), %ymm0
        vmovaps %ymm0, (%rcx)
        `, "{rcx},{rdx},i", dest, src, 32                                    
        );
}
} // version(LDC)

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

__gshared float f1,f2,f3,f4,f5,f6,f7,f8;

public:

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
