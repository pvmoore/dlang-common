module common.io.byte_reader;

import common.io;
import common.utils;
import std.stdio : File, SEEK_SET;

final class FileByteReader : ByteReader {
private:
    string filename;
    File file;
public:
    this(string filename, uint bufferSize=2048, bool littleEndian=true) {
	    this.filename      = filename;
		this.file          = File(filename, "rb");
        super(file.size, littleEndian);
		this.buffer.length = bufferSize;

        this.bufpos = buffer.length;
	}
    override void close() {
        super.close();
        file.close();
    }
    override FileByteReader rewind() {
        position = 0;
        bufpos   = buffer.length;
        file.rewind();
        return this;
    }
    override FileByteReader skip(ulong numBytes) {
        super.skip(numBytes);

        if(bufpos >= buffer.length) {
            /* invalidate our buffer and skip through the actual file */
            file.seek(position, SEEK_SET);
            bufpos = buffer.length;
        }
        return this;
    }
protected:
    override ubyte readByte() {
        return doRead!ubyte;
    }
    override ushort readShort() {
        return doRead!ushort;
    }
    override uint readInt() {
        return doRead!uint;
    }
    override ulong readLong() {
        return doRead!ulong;
    }
    override float readFloat() {
        return doRead!float;
    }
    override ubyte[] readByteArray(ulong items) {
        return doReadArray!ubyte(items);
    }
    override ushort[] readShortArray(ulong items) {
        return doReadArray!ushort(items);
    }
    override uint[] readIntArray(ulong items) {
        return doReadArray!uint(items);
    }
    override ulong[] readLongArray(ulong items) {
        return doReadArray!ulong(items);
    }
    override float[] readFloatArray(ulong items) {
        return doReadArray!float(items);
    }
private:
    void prefetch(uint numBytes) {
        if(bufpos+numBytes >= buffer.length) {
            auto rem = buffer.length-bufpos;
            if(rem>0) {
                buffer[0..rem] = buffer[bufpos..$];
            }
            auto len = file.rawRead(buffer[rem..$]).length;
            bufpos = 0;
        }
    }
    T doRead(T)() {
        prefetch(T.sizeof);

        auto i    = bufpos;
        bufpos   += T.sizeof;
        position += T.sizeof;
        return *cast(T*)(buffer.ptr+i);
    }
    T[] doReadArray(T)(ulong items) {
        auto numBytes = items*T.sizeof;

        //writefln("readArray(%s) numBytes=%s bufpos=%s", items, numBytes, bufpos); flushStdErrOut();

        /* We have the whole array in buffer - just copy it */
	    if(bufpos+numBytes < buffer.length) {
            auto i    = bufpos;
            bufpos   += numBytes;
            position += numBytes;
            T* p = cast(T*)(buffer.ptr+i);
            return p[0..items].dup;
	    }

	    /* copy what we have in the buffer */
        auto rem = buffer.length - bufpos;
        auto array = new T[items];
        ubyte* p = cast(ubyte*)array.ptr;
        p[0..rem] = buffer[bufpos..$].dup;

        if(rem<numBytes) {
            /* read the rest from the file */
            file.rawRead(p[rem..numBytes]);
        }

        position += numBytes;
        bufpos    = buffer.length;

	    return array;
    }
}

//##############################################################################################

class ByteReader {
protected:
    ubyte[] buffer;
	ulong bufpos;
	bool LE;

    this(ulong length, bool littleEndian=true) {
        this.length = length;
        this.LE     = littleEndian;
        expect(littleEndian, "Big endian not currently supported");
    }
public:
    ulong length;
    ulong position;

    ulong remaining() { return length - position; }

    this(ubyte[] source, bool littleEndian=true) {
        this(source.length, littleEndian);
        this.buffer = source.dup;
    }
    /**
     *  Create a BitReader that uses this ByteReader as the byte source.
     */
    BitReader getBitReader() {
        return new BitReader(()=>read!ubyte);
    }
	void close() {
	    position = length;
	}
	ByteReader rewind() {
	    position = 0;
	    bufpos   = 0;
        return this;
	}
    ByteReader skip(ulong numBytes) {
	    position += numBytes;
        bufpos   += numBytes;
        return this;
	}
	final bool eof() const {
	    return position >= length;
    }
    T peek(T)(int offset = 0) {
        // Only implemented for the base class
        assert(cast(FileByteReader)this is null);

        auto savedBufpos   = bufpos;
        auto savedPosition = position;

        bufpos   += T.sizeof*offset;
        position += T.sizeof*offset;

        T value;
        if(bufpos >= length) {
            value = T.init;
        } else {
            value = read!T;
        }

        bufpos   = savedBufpos;
        position = savedPosition;
        return value;
    }
	T read(T)() {
	    if(eof()) {
	        position = length;
	        return T.init;
        }
        static if(is(T==ubyte) || is(T==byte) || is(T==char)) return cast(T)readByte();
        else static if(is(T==ushort) || is(T==short) || is(T==wchar)) return cast(T)readShort();
        else static if(is(T==uint) || is(T==int) || is(T==dchar)) return cast(T)readInt();
        else static if(is(T==ulong) || is(T==long)) return readLong();
        else static if(is(T==float)) return readFloat();
        else static if(isStruct!T) return *cast(T*)readByteArray(T.sizeof).ptr;
        else static assert(false);
	}
    T[] readArray(T)(ulong items) {
        if(eof()) {
            return new T[items];
        }
        static if(is(T==ubyte) || is(T==byte) || is(T==char)) return cast(T[])readByteArray(items);
        else static if(is(T==ushort) || is(T==short) || is(T==wchar)) return cast(T[])readShortArray(items);
        else static if(is(T==uint) || is(T==int) || is(T==dchar)) return cast(T[])readIntArray(items);
        else static if(is(T==ulong) || is(T==long)) return readLongArray(items);
        else static if(is(T==float)) return readFloatArray(items);
        else static if(isStruct!T) return cast(T[])readByteArray(items*T.sizeof);
        else static assert(false);
	}
protected:
    ubyte readByte() {
        return doRead!ubyte;
    }
    ushort readShort() {
        return doRead!ushort;
    }
    uint readInt() {
        return doRead!uint;
    }
    ulong readLong() {
        return doRead!ulong;
    }
    float readFloat() {
        return doRead!uint.bitcastTo!float;
    }
    ubyte[] readByteArray(ulong items) {
        return doReadArray!ubyte(items);
    }
    ushort[] readShortArray(ulong items) {
        return doReadArray!ushort(items);
    }
    uint[] readIntArray(ulong items) {
        return doReadArray!uint(items);
    }
    ulong[] readLongArray(ulong items) {
        return doReadArray!ulong(items);
    }
    float[] readFloatArray(ulong items) {
        return doReadArray!float(items);
    }
private:
    T doRead(T)() {
        if(position+T.sizeof > length) {
            // We are reading past the end of the input
            auto value = T.init;
            foreach(i; bufpos..bufpos+T.sizeof) {
                value >>>= 8;
                if(bufpos<length) {
                    value |= buffer[bufpos];
                }
            }
            position = length;
            return value;
        }
        auto i    = bufpos;
        bufpos   += T.sizeof;
        position += T.sizeof;
        return *cast(T*)(buffer.ptr+i);
    }
    T[] doReadArray(T)(ulong items) {
        auto numBytes = items*T.sizeof;

        // we can just copy from buffer
	    if(bufpos+numBytes <= buffer.length) {
            auto i    = bufpos;
            bufpos   += numBytes;
            position += numBytes;
            T* p = cast(T*)(buffer.ptr+i);
            return p[0..items].dup;
	    }
	    // copy what we have in the buffer
        auto rem   = buffer.length - bufpos;
        auto array = new T[items];
        ubyte* p   = cast(ubyte*)array.ptr;

        p[0..rem] = buffer[bufpos..$].dup;

        position += numBytes;
        bufpos    = buffer.length;

	    return array;
    }
}
