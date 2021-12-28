module common.io.bit_reader;

import common.io;
import common.utils.utilities : throwIf;

class BitReader {
protected:
    ubyte delegate() getByte;
    ulong bits;
    uint bitpos; // 0..31
    uint numBitsRead;
public:
    this(ubyte delegate() byteProvider) {
        this.getByte = byteProvider;
    }
    uint getNumBitsRead() {
        return numBitsRead;
    }
    uint read(uint numBits) {
        if(numBits==0) return 0;
        throwIf(numBits>32, "numBits must be <= 32");

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

        numBitsRead += numBits;

        return cast(uint)value;
    }
    bool isAtStartOfByte() {
        return bitpos == 0;
    }
    void skipToEndOfByte() {
        read(bitpos%8);
    }
    void skipBits(uint numBits) {
        read(numBits);
    }
}

// ═════════════════════════════════════════════════════════════════════════════════════════════════

final class ArrayBitReader : BitReader {
private:
    ubyte[] array;
    uint bytePos;

    ubyte provider() {
        throwIf(bytePos >= array.length, "Index %s >= %s", bytePos, array.length);
        return array[bytePos++];
    }
public:
    this(ubyte[] array) {
        this.array = array;
        super(&provider);
    }
    this(ushort[] array) {
        this(cast(ubyte[])array);
    }
    this(uint[] array) {
        this(cast(ubyte[])array);
    }
    this(ulong[] array) {
        this(cast(ubyte[])array);
    }
    void moveTo(uint bitOffset) {

    }
}

// ═════════════════════════════════════════════════════════════════════════════════════════════════

final class FileBitReader : BitReader {
private:
    FileByteReader byteReader;
public:
    this(string filename) {
        byteReader = new FileByteReader(filename);
        super(()=>byteReader.read!ubyte);
    }
    void close() {
        byteReader.close();
    }
}
