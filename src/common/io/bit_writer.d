module common.io.bit_writer;
/**
 *  Call write to write 0 to 32 bits per call.
 *  Receiver delegate is called when a ubyte is filled up.
 */
import common.io;
import common.utils;
import std.stdio : File;

final class FileBitWriter {

    this(string filename) {
        this.writer = new BitWriter(&receiveByte);
        this.file.open(filename, "wb");
        this.array = new ubyte[BUFFER_LEN];
    }
    void close() {
        writer.flush();
        writeBuffer();
        file.close();
    }
    void write(uint value, uint numBits) {
        writer.write(value, numBits);
    }
    void writeOnes(uint count) {
        writer.writeOnes(count);
    }
    void writeZeroes(uint count) {
        writer.writeZeroes(count);
    }
private:
    const BUFFER_LEN = 2048;
    BitWriter writer;
    File file;
    ubyte[] array;
    uint pos;

    void receiveByte(ubyte b) {
        if(pos==BUFFER_LEN) {
            writeBuffer();
        }
        array[pos++] = b;
    }
    void writeBuffer() {
        if(pos==0) return;
        file.rawWrite(array[0..pos]);
        pos = 0;
    }
}
//-----------------------------------------------------------------

final class ArrayBitWriter : BitWriter {
private:
    ubyte[] array;

    void writeByte(ubyte b) {
        array ~= b;
    }
public:
    uint length() {
        return array.length.as!uint;
    }
    ubyte[] getArray() {
        return array;
    }
    this(uint reserved = 1024) {
        super(&writeByte);
        this.array.reserve(reserved);
    }
}

/**
 * ubyte[] received;
 * void receiver(ubyte b) {
 *     received ~= b;
 * }
 * auto writer = new BitWriter(&receiver);
 *
 * writer.write(0b11111111, 8);
 */
class BitWriter {
private:
	ulong bits;
    uint bitpos;
    void delegate(ubyte) receiver;
public:
    this(void delegate(ubyte) receiver) {
        this.receiver = receiver;
    }
    uint bitsWritten;
    uint bytesWritten;
    /**
     *  Write 0 to 32 bits of value to the stream.
     */
    BitWriter write(uint value, uint numBits) {
        expect(numBits<33);
        if(numBits!=0) {

            ulong a = value & (0xffff_ffffu >>> (32-numBits));
            ulong b = a << bitpos;

            bits        |= b;
            bitpos      += numBits;
            bitsWritten += numBits;

            while(bitpos>7) {
                //receiver(cast(ubyte)((bits>>>bitpos-8) & 0xff));
                receiver(cast(ubyte)(bits & 0xff));
                bits >>>=8;
                bitpos -= 8;
                bytesWritten++;
            }
        }
        return this;
    }
    BitWriter writeOnes(uint count) {
        if(count!=0) {
            uint rem = count%32;
            for(auto i=0; i<count/32; i++) write(0xffff_ffff,32);
            for(auto i=0; i<rem; i++) write(1,1);
        }
        return this;
    }
    BitWriter writeZeroes(uint count) {
        if(count!=0) {
            uint rem = count%32;
            for(auto i=0; i<count/32; i++) write(0,32);
            for(auto i=0; i<rem; i++) write(0,1);
        }
        return this;
    }
    auto flush() {
        if(bitpos>0) {
            bytesWritten++;
            bitsWritten += (8-bitpos);

            receiver(cast(ubyte)(bits & 0xff));
            bitpos = 0;
            bits   = 0;
        }
        return this;
    }
    auto alignTo(uint alignment) {
        assert(alignment>1);
        assert(From!"core.bitop".popcnt(alignment)==1);

        uint and = alignment-1;
        uint rem = alignment - (bitsWritten & and);

        if(rem != alignment) {
            write(0, rem);
        }

        return this;
    }
}


