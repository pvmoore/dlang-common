module common.utils.cpu_utils;

import common.all;

enum AVX512Feature : uint {
    NONE            = 0,
    F               = 1<<0,     // Foundation
    BITALG          = 1<<1,     // Bit Algorithms
    DQ              = 1<<2,     // Doubleword and Quadword
    IFMA            = 1<<3,     // Integer Fused Multiply Add
    PF              = 1<<4,     // Prefetch
    ER              = 1<<5,     // Exponent and Reciprocal
    CD              = 1<<6,     // Conflict Detection
    BW              = 1<<7,     // Byte and Word
    VL              = 1<<8,     // Vector Length
    VBMI            = 1<<9,     // Vector Bit Manipulation
    VBMI2           = 1<<10,    // Vector Bit Manipulation
    VNNI            = 1<<11,    // Vector Neural Network Instructions
    VPOPCNTDQ       = 1<<12,    // Vector Popcnt Doubleword and Quadword
    _4VNNIW         = 1<<13,    // Vector Neural Network Instructions Word Variable Precision
    _4FMAPS         = 1<<14,    // Fused Multiply Accumulation Packed Single Precision
    BF16            = 1<<15,    // BFloat 16 Instructions
    VP2INTERSECT    = 1<<16,    // Double words and Quadword Intersect
}

uint getAVX512Support() {
    uint _eax, _ebx, _ecx, _edx;

version(DigitalMars) {
    asm pure nothrow @nogc {
        push RBX;

        mov EAX, 0x07;
        mov ECX, 0;
        cpuid;
        mov _ebx, EBX;
        mov _ecx, ECX;
        mov _edx, EDX;

        mov EAX, 0x07;
        mov ECX, 1;
        cpuid;
        mov _eax, EAX;

        pop RBX;
    }
}
version(LDC) {
    import ldc.llvmasm;
    import ldc.attributes;
    // See https://wiki.dlang.org/LDC_inline_assembly_expressions


}
    uint features =
        (_ebx.isSet(1<<16) ? AVX512Feature.F : 0) +
        (_ebx.isSet(1<<17) ? AVX512Feature.DQ : 0) +
        (_ebx.isSet(1<<21) ? AVX512Feature.IFMA : 0) +
        (_ebx.isSet(1<<26) ? AVX512Feature.PF : 0) +
        (_ebx.isSet(1<<27) ? AVX512Feature.ER : 0) +
        (_ebx.isSet(1<<28) ? AVX512Feature.CD : 0) +
        (_ebx.isSet(1<<30) ? AVX512Feature.BW : 0) +
        (_ebx.isSet(1<<31) ? AVX512Feature.VL : 0) +

        (_ecx.isSet(1<<1) ? AVX512Feature.VBMI : 0) +
        (_ecx.isSet(1<<6) ? AVX512Feature.VBMI2 : 0) +
        (_ecx.isSet(1<<11) ? AVX512Feature.VNNI : 0) +
        (_ecx.isSet(1<<12) ? AVX512Feature.BITALG : 0) +
        (_ecx.isSet(1<<14) ? AVX512Feature.VPOPCNTDQ : 0) +

        (_edx.isSet(1<<2) ? AVX512Feature._4VNNIW : 0) +
        (_edx.isSet(1<<3) ? AVX512Feature._4FMAPS : 0) +
        (_edx.isSet(1<<8) ? AVX512Feature.VP2INTERSECT : 0) +

        (_eax.isSet(1<<5) ? AVX512Feature.BF16 : 0);

    return features;
}