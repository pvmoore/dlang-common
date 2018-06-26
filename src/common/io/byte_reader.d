module common.io.byte_reader;
/**
 *
 */
import common.all;
import std.stdio : File, SEEK_CUR;

final class ByteReader {
    File file;
    ubyte[] buffer;
	ulong bufpos;
	bool LE;
public:
    string filename;
    ulong length;
    ulong position;

	this(string filename, uint bufferSize=2048, bool littleEndian=true) {
	    this.filename      = filename;
		this.file          = File(filename, "rb");
		this.LE            = littleEndian;
		this.length        = file.size;
		this.buffer.length = bufferSize;
		expect(littleEndian, "Big endian not current supported");
	}
	void close() {
	    file.close();
	    position = length;
	}
	void rewind() {
	    position = 0;
	    bufpos = 0;
	    file.rewind();
	}
	bool eof() const {
	    return position >= length;
    }
	T read(T)() {
	    if(position+T.sizeof > length) {
	        position = length;
	        return T.init;
        }
        prefetch(T.sizeof);
        auto i    = bufpos;
        bufpos   += T.sizeof;
        position += T.sizeof;
        return *cast(T*)(buffer.ptr+i);
	}
	T[] readArray(T)(ulong items) {
        auto numBytes = items*T.sizeof;

        //writefln("readArray(%s) numBytes=%s bufpos=%s", items, numBytes, bufpos); flushStdErrOut();

        // we can just copy from buffer
	    if(bufpos+numBytes < buffer.length) {
            auto i    = bufpos;
            bufpos   += numBytes;
            position += numBytes;
            T* p = cast(T*)(buffer.ptr+i);
            return p[0..items].dup;
	    }
	    // copy what we have in the buffer
        auto rem = buffer.length - bufpos;
        auto array = new T[items];
        ubyte* p = cast(ubyte*)array.ptr;
        p[0..rem] = buffer[bufpos..$].dup;

        if(rem<numBytes) {
            // read the rest from the file
            file.rawRead(p[rem..numBytes]);
        }

        position += numBytes;
        bufpos = buffer.length;

	    return array;
	}
	void skip(ulong numBytes) {
	    position += numBytes;

        if(bufpos+numBytes < buffer.length) {
            // just update our internal ptr
            bufpos += numBytes;
        } else {
            // invalidate our buffer and skip through the actual file
            auto rem = buffer.length-bufpos;
            file.seek(numBytes - rem, SEEK_CUR);
            bufpos = buffer.length;
        }
	}
private:
    void prefetch(uint count) {
        if(position==0) {
            file.rawRead(buffer);
        } else if(bufpos+count >= buffer.length) {
            auto rem = buffer.length-bufpos;
            if(rem>0) {
                buffer[0..rem] = buffer[bufpos..$];
            }
            auto len = file.rawRead(buffer[rem..$]).length;
            bufpos = 0;
        }
    }
}
