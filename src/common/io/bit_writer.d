module common.io.bit_writer;
/**
 *  Call write to write 0 to 32 bits per call.
 *  Receiver delegate is called when a ubyte is filled up.
 */
import common.all;
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

final class BufferBitWriter {
private:
    BitWriter writer;
    ubyte[] _buffer;

    void writeByte(ubyte b) {
        _buffer ~= b;
    }
public:
    this(uint reserved = 1024) {
        this.writer = new BitWriter(&writeByte);
        this._buffer.reserve(reserved);
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
    uint bitsWritten() {
        return writer.bitsWritten;
    }
    uint bytesWritten() {
        return writer.bytesWritten;
    }
    uint length() {
        return _buffer.length.as!uint;
    }
    ubyte[] flushAndGetBuffer() {
        writer.flush();
        return _buffer;
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
final class BitWriter {
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
    void write(uint value, uint numBits) {
        expect(numBits<33);
        if(numBits==0) return;

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
    void writeOnes(uint count) {
        if(count==0) return;
        uint rem = count%32;
        for(auto i=0; i<count/32; i++) write(0xffff_ffff,32);
        for(auto i=0; i<rem; i++) write(1,1);
    }
    void writeZeroes(uint count) {
        if(count==0) return;
        uint rem = count%32;
        for(auto i=0; i<count/32; i++) write(0,32);
        for(auto i=0; i<rem; i++) write(0,1);
    }
    void flush() {
        if(bitpos>0) {
            bytesWritten++;
            bitsWritten += (8-bitpos);

            receiver(cast(ubyte)(bits & 0xff));
            bitpos = 0;
            bits   = 0;
        }
    }
}


