module common.io.bit_reader;
/**
 *
 */
import common.all;

final class BitReader {
private:
    ubyte delegate() getByte;
    ulong bits;
    uint bitpos;
public:
    this(ubyte delegate() byteProvider) {
        this.getByte = byteProvider;
    }
    uint read(uint numBits) {
        if(numBits==0) return 0;

        while(bitpos<numBits) {
            ulong b = getByte();
            b     <<= bitpos;
            bits   |= b;
            bitpos += 8;
        }
        ulong mask  = 0xffff_ffffu >> (32-numBits);
        ulong value = bits & mask;

        bits >>>= numBits;
        bitpos -= numBits;

        return cast(uint)value;
    }
}

