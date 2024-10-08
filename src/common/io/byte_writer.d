module common.io.byte_writer;

import common.io;
import common.utils;
import std.stdio : File;
import core.bitop : byteswap, bswap;

abstract class ByteWriter {
public:
    ulong getBytesWritten() const { return bytesWritten; }

    this(bool littleEndian = true) {
        this.LE = littleEndian;
    }
    void write(T)(T value) {
        static if(is(T==ubyte) || is(T==byte) || is(T==char)) writeByte(value.as!ubyte);
        else static if(is(T==ushort) || is(T==short)) writeShort(value);
        else static if(is(T==uint) || is(T==int)) writeInt(value);
        else static if(is(T==ulong) || is(T==long)) writeLong(value);
        else static if(is(T==float)) writeFloat(value);
        else static if(isStruct!T) writeBytes((&value).as!(ubyte*), T.sizeof);
        else static assert(false);

        bytesWritten += T.sizeof;
    }
    void writeArray(T)(T[] items) {
        static if(is(T==ubyte) || is(T==byte) || is(T==char)) writeByteArray(items.as!(ubyte[]));
        else static if(is(T==ushort) || is(T==short)) writeShortArray(items);
        else static if(is(T==uint) || is(T==int)) writeIntArray(items);
        else static if(is(T==ulong) || is(T==long)) writeLongArray(items);
        else static if(is(T==float)) writeFloatArray(items);
        else static if(isStruct!T) writeBytes(items.ptr.as!(ubyte*), (T.sizeof*items.length).as!uint);
        else {
            pragma(msg, "%s not supported".format(T.stringof));
            static assert(false);
        }
        bytesWritten += T.sizeof*items.length;
    }
    /**
     *  Create a BitWriter that uses this ByteWriter as the destination.
     */
    final BitWriter getBitWriter() {
        return new BitWriter((it)=>write!ubyte(it));
    }
protected:
    bool LE;
    ulong bytesWritten;

    abstract void writeByte(ubyte value);
    abstract void writeShort(ushort value);
    abstract void writeInt(uint value);
    abstract void writeLong(ulong value);
    abstract void writeFloat(float value);

    abstract void writeBytes(ubyte* ptr, uint count);
    abstract void writeByteArray(ubyte[] items);
    abstract void writeShortArray(ushort[] items);
    abstract void writeIntArray(uint[] items);
    abstract void writeLongArray(ulong[] items);
    abstract void writeFloatArray(float[] items);

    ushort swap(ushort v) { return LE ? v : byteswap(v); }
    uint swap(uint v) { return LE ? v : bswap(v); }
    ulong swap(ulong v) { return LE ? v : bswap(v); }
    float swap(float v) { return LE ? v : bswap(v.bitcastTo!uint).bitcastTo!float; }
}

final class ArrayByteWriter : ByteWriter {
private:
    ubyte[] array;
public:
    ulong length;
    ubyte[] getArray() { return array[0..length]; }
    ulong getReservedLength() { return array.length; }

    this(uint initialSize = 256, bool littleEndian = true) {
        super(littleEndian);
        array.length = initialSize;
    }
    void reset() {
        length = 0;
    }
    void pack() {
        array.length = length;
    }
protected:
    override void writeByte(ubyte value) {
        expand(1);
        array[length++] = value;
    }
    override void writeShort(ushort value) {
        expand(2);
        *ptr!ushort() = swap(value);
        length += 2;
    }
    override void writeInt(uint value) {
        expand(4);
        *ptr!uint() = swap(value);
        length += 4;
    }
    override void writeLong(ulong value) {
        expand(8);
        *ptr!ulong() = swap(value);
        length += 8;
    }
    override void writeFloat(float value) {
        expand(4);
        *ptr!float() = swap(value);
        length += 4;
    }
    override void writeBytes(ubyte* ptr, uint count) {
        throwIf(!LE, "Writing structs in big endian mode is not currently supported");
        expand(count);
        array[length..length+count] = ptr[0..count];
        length += count;
    }
    override void writeByteArray(ubyte[] items) {
        expand(items.length);
        array[length..length+items.length] = items;
        length += items.length;
    }
    override void writeShortArray(ushort[] items) {
        expand(items.length*2);
        auto p = ptr!ushort;
        if(LE) {
            p[0..items.length] = items;
        } else {
            foreach(i; 0..items.length) {
                p[i] = swap(items[i]);
            }
        }
        length += items.length*2;
    }
    override void writeIntArray(uint[] items) {
        expand(items.length*4);
        auto p = ptr!uint;
        if(LE) {
            p[0..items.length] = items;
        } else {
            foreach(i; 0..items.length) {
                p[i] = swap(items[i]);
            }
        }
        length += items.length*4;
    }
    override void writeLongArray(ulong[] items) {
        expand(items.length*8);
        auto p = ptr!ulong;
        if(LE) {
            p[0..items.length] = items;
        } else {
            foreach(i; 0..items.length) {
                p[i] = swap(items[i]);
            }
        }
        length += items.length*8;
    }
    override void writeFloatArray(float[] items) {
        expand(items.length*4);
        auto p = ptr!float;
        if(LE) {
            p[0..items.length] = items;
        } else {
            foreach(i; 0..items.length) {
                p[i] = swap(items[i]);
            }
        }
        length += items.length*4;
    }
private:
    T* ptr(T)() {
        return cast(T*)(array.ptr+length);
    }
    void expand(ulong numBytes) {
        if(length+numBytes >= array.length) {
            array.length += array.length + numBytes;
        }
    }
}

final class FileByteWriter : ByteWriter {
private:
    File file;
public:
    this(string filename, bool littleEndian = true) {
        super(littleEndian);

        throwIf(!littleEndian, "Big endian not currently supported");

        this.file = File(filename, "wb");
    }
    void close() { file.close(); }
    void flush() { file.flush(); }
protected:
    override void writeByte(ubyte value) {
        file.rawWrite([value]);
    }
    override void writeShort(ushort value) {
         file.rawWrite([value]);
    }
    override void writeInt(uint value) {
         file.rawWrite([value]);
    }
    override void writeLong(ulong value) {
         file.rawWrite([value]);
    }
    override void writeFloat(float value) {
         file.rawWrite([value]);
    }
    override void writeBytes(ubyte* ptr, uint count) {
        file.rawWrite(ptr[0..count]);
    }
    override void writeByteArray(ubyte[] items) {
        file.rawWrite(items);
    }
    override void writeShortArray(ushort[] items) {
        file.rawWrite(items);
    }
    override void writeIntArray(uint[] items) {
        file.rawWrite(items);
    }
    override void writeLongArray(ulong[] items) {
        file.rawWrite(items);
    }
    override void writeFloatArray(float[] items) {
        file.rawWrite(items);
    }
}
