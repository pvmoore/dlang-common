module common.utils.bit_utils;

import common.all;
import core.bitop : bsr, bsf, popcnt;


/*
 * Returns the number of bits set to 1 in the input value.
 */
uint bitCount(T)(T value) if(isInteger!T || isEnum!T) {
    import core.bitop : popcnt;
    return popcnt(value);
}

/**
 * Returns the next highest power of 2.
 * Assumes v is not zero.
 */ 
T nextHighestPowerOf2(T)(T v) pure nothrow if(isInteger!T) {
    if(popcnt(v) == 1) return v;
    return (cast(T)1) << (bsr(v) + 1);
}

/**
 * Returns true if v is a power of 2.
 */
bool isPowerOf2(T)(T v) pure nothrow if(isInteger!T) {
   return popcnt(v) == 1;
}

/**
 * Returns the number of bits set in v.
 */
bool isSet(T,E)(T value, E flag) if((is(T==enum) || isInteger!T) && (is(E==enum) || isInteger!E)) {
    return (value & flag) == flag;
}

/**
 * Returns true if the flag is not set.
 */
bool isUnset(T,E)(T value, E flag) if((is(T==enum) || isInteger!T) && (is(E==enum) || isInteger!E)) {
    return (value & flag) == 0;
}

/**
 * Return the value with the specified alignment.
 * eg. value=3, align=4 => 4
 */
ulong getAlignedValue(ulong value, uint alignment) {
    // Assume alignment is a power of 2
    ulong mask = alignment-1;
    return (value + mask) & ~mask;
}

/**
 *  double a = 3.14;
 *  ulong b  = a.bitcastTo!ulong()
 */
T bitcastTo(T,F)(F from) {
    T* p =cast(T*)&from;
    return *p;
}

/**
 * Extracts a number of bits from an unsigned integer value.
 * Works identically to the GLSL function of the same name.
 */
T bitfieldExtract(T)(T value, uint bitPos, uint numBits) if(isInteger!T && !isArray!T) {
    enum SIZE = T.sizeof*8;
    if(numBits==0) return 0;
    if(bitPos >= SIZE) return 0;
    if(numBits > SIZE) numBits = SIZE;

    T mask = cast(T)-1;

    value >>>= bitPos;
    value &= (mask >>> (SIZE-numBits));
    return value;
}

/**
 * Return up to 32 bits from _bits_ array.
 *
 */
uint bitfieldExtract(ubyte[] bits, uint bitPos, uint numBits) {
    if(numBits == 0) return 0;
    auto bytePos = bitPos / 8;
    throwIf(bytePos >= bits.length, "%s >= %s", bytePos, bits.length);
    throwIf(numBits > 32, "numBits must be 32 or less");

    bitPos &= 7;

    uint shift = 32-numBits;
    uint value;

    if(bitPos != 0) {
        auto n = 8-bitPos;
        if(n > numBits) n = numBits;

        value = bitfieldExtract(bits[bytePos], bitPos, n) << (32-n);

        bitPos = 0;
        bytePos++;
        numBits -= n;

        throwIf(bytePos >= bits.length, "%s >= %s", bytePos, bits.length);
    }

    foreach(i; 0..numBits/8) {
        value >>>= 8;
        value |= (bits[bytePos] << 24);

        bytePos++;
        numBits -= 8;

        throwIf(bytePos >= bits.length, "%s >= %s", bytePos, bits.length);
    }

    if(numBits > 0) {
        value >>>= numBits;
        value |= (bitfieldExtract(bits[bytePos], bitPos, numBits) << (32-numBits));
    }

    return value >>> shift;
}
