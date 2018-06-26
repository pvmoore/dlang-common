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
final class BitWriter {
private:
	ulong bits;
    uint bitpos;
    void delegate(ubyte) receiver;
public:
    this(void delegate(ubyte) receiver) {
        this.receiver = receiver;
    }
    /**
     *  Write 0 to 32 bits of value to the stream.
     */
    void write(uint value, uint numBits) {
        expect(numBits<33);
        if(numBits==0) return;

        ulong a = value & (0xffff_ffffu >>> (32-numBits));
        ulong b = a << bitpos;

        bits   |= b;
        bitpos += numBits;

        while(bitpos>7) {
            //receiver(cast(ubyte)((bits>>>bitpos-8) & 0xff));
            receiver(cast(ubyte)(bits & 0xff));
            bits >>>=8;
            bitpos -= 8;
        }
    }
    void flush() {
        if(bitpos>0) {
            receiver(cast(ubyte)(bits & 0xff));
            bitpos = 0;
            bits   = 0;
        }
    }
}


