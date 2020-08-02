module _tests.test_io;

import std : format, writefln, remove, tempDir, uniform, Mt19937, File, to, exists, unpredictableSeed;

import common.all;

void testIo() {
    testByteReader();
    testFileByteWriter();
    testArrayByteWriter();
    testBitWriter();
    testBitReader();
    testBitReaderAndWriter();
    testConsole();
}

void testByteReader() {
    writefln("--== Testing ByteReader ==--");

    {
        writefln("FileByteReader...");
        string dir = tempDir();
        string filename = dir~uniform(0,100).to!string~"file.bin";
        scope f = File(filename, "wb");
        scope(exit) { remove(filename); }
        ubyte[256] data;

        void writeTestData() {
            for(auto i=0; i<data.length; i++) {
                data[i] = cast(ubyte)uniform(0,255);
            }
            f.rawWrite(data);
        }
        writeTestData();
        f.close();

        // read
        FileByteReader r = new FileByteReader(filename, 8);
        scope(exit) r.close();

        assert(r.length==256);
        assert(r.position==0);

        auto b1 = r.read!ubyte;
        assert(b1==data[0]);
        assert(r.position==1);

        auto s1 = r.read!ushort();
        assert(s1==(data[1] | data[2]<<8));
        assert(r.position==3);

        auto i1 = r.read!uint();
        assert(i1==(data[3] | (data[4]<<8) | (data[5]<<16) | (data[6]<<24)));
        assert(r.position==7);

        auto l1 = r.read!ulong();
        assert(l1==(
            cast(ulong)data[7] | (cast(ulong)data[8]<<8) | (cast(ulong)data[9]<<16) | (cast(ulong)data[10]<<24) |
            (cast(ulong)data[11]<<32) | (cast(ulong)data[12]<<40) | (cast(ulong)data[13]<<48) | (cast(ulong)data[14]<<56)
        ));
        assert(r.position==15);

        auto b2 = r.read!ubyte();
        assert(b2==data[15]);
        assert(r.position==16);

        auto s2 = r.read!ushort;
        assert(s2==(data[16] | (data[17]<<8)));
        assert(r.position==18);

        auto s3 = r.read!ushort;
        assert(s3==(data[18] | (data[19]<<8)));
        assert(r.position==20);

        auto i2 = r.read!uint;
        assert(i2==(data[20] | (data[21]<<8) | (data[22]<<16) | (data[23]<<24)));
        assert(r.position==24);

        // readArray
        auto a1 = r.readArray!ubyte(2);
        assert(a1==data[24..24+2]);
        assert(r.position==26);

        auto a2 = r.readArray!ubyte(5);
        assert(a2==data[26..26+5]);
        assert(r.position==31);

        auto a3 = r.readArray!ubyte(12);
        assert(a3==data[31..31+12]);
        assert(r.position==43);

        // skip
        auto b3 = r.read!ubyte;
        assert(b3==data[43]);
        assert(r.position==44);

        r.skip(2);
        assert(r.position==46);

        r.skip(9);
        assert(r.position==55);
        r.close();
    }

    {
        writefln("ByteReader...");
        ubyte[] b = [cast(ubyte)1,2,3,4,5,6,7,8,9,0];
        auto reader = new ByteReader(b);
        assert(reader.length==b.length);

        ubyte[] buf;

        while(!reader.eof) {
            buf ~= reader.read!ubyte;
        }
        assert(buf.length==b.length);
        assert(buf[] == b[]);


        reader.rewind();
        assert(reader.position==0);
        assert(reader.read!ushort==(0x0201).as!ushort && reader.position==2);
        assert(reader.read!uint==(0x06050403).as!uint && reader.position==6);
        reader.skip(1);
        assert(reader.position==7);
        assert(reader.read!ubyte==(0x08).as!ubyte && reader.position==8);
        assert(reader.read!uint==(0x00000009).as!uint && reader.position==10 && reader.eof);

        assert(reader.read!ubyte==0);

        reader.rewind();
        assert(reader.position==0);

        assert(reader.readArray!ubyte(3) == cast(ubyte[])[1,2,3] && reader.position==3);
        assert(reader.readArray!ushort(2) == cast(ushort[])[0x0504, 0x0706] && reader.position==7);
        assert(reader.readArray!ubyte(8) == cast(ubyte[])[8,9,0,0,0,0,0,0] && reader.eof);

        reader.rewind();

        assert(reader.readArray!uint(5) == [0x04030201, 0x08070605, 0x00000009, 0,0]);

        reader.close();
        assert(reader.eof);
    }
    {   // peek
        ubyte[] b = [cast(ubyte)1,2,3,4,5,6,7,8,9,0];
        auto r    = new ByteReader(b);

        assert(r.peek!ubyte    == 1);
        assert(r.peek!ubyte(1) == 2);
        assert(r.peek!ubyte(2) == 3);
        assert(r.peek!ubyte(3) == 4);

        assert(1 == r.read!ubyte);

        assert(r.peek!ubyte(0) == 2);
        assert(r.peek!ubyte(1) == 3);
        assert(r.peek!ubyte(2) == 4);
    }
    {
        // float
        float[] f = [3.14f, 99f, 60f, 77f];
        ubyte[] b = cast(ubyte[])f;
        assert(b.length == 16);
        assert(b.ptr.as!(float*)[0..4] == f);

        auto r = new ByteReader(b);

        assert(r.read!float == 3.14f);
        assert(r.readArray!float(3) == [99f, 60f, 77f]);
    }
    {   // readArray (of structs)
        struct S {
            uint a; uint b;
        }
        S[] array = [S(1,2), S(3,4), S(5,6), S(7,8)];
        ubyte[] b = cast(ubyte[])array;

        auto r = new ByteReader(b);

        assert(r.read!S==S(1,2));
        assert(r.readArray!S(3) == [S(3,4), S(5,6), S(7,8)]);
    }
}
void testFileByteWriter() {
    writefln("Testing FileByteWriter...");

    string dir = tempDir();
    string filename = dir~uniform(0,100).to!string~"file.bin";
    scope(exit) { if(exists(filename)) remove(filename); }

    struct S { uint a; uint b; }

    {
        auto w = new FileByteWriter(filename);

        w.write!ubyte(0xfe);
        assert(w.getBytesWritten==1);
        w.write!byte(-1);
        assert(w.getBytesWritten==2);
        w.write!ushort(0xee11);
        assert(w.getBytesWritten==4);
        w.write!uint(0xff);
        assert(w.getBytesWritten==8);
        w.write!ulong(0);
        assert(w.getBytesWritten==16);
        w.write!float(3.14f);
        assert(w.getBytesWritten==20);
        w.write!S(S(4,5));
        assert(w.getBytesWritten==28);

        auto bw = w.getBitWriter();
        bw.write(0b101, 3);
        bw.flush();         // push the current byte out to the ByteWriter

        w.close();
    }
    auto r = new FileByteReader(filename);

    assert(r.read!ubyte==0xfe);
    assert(r.read!byte==-1);
    assert(r.read!ushort==0xee11);
    assert(r.read!uint==0xff);
    assert(r.read!ulong==0);
    assert(r.read!float==3.14f);
    assert(r.read!S == S(4,5));

    assert(r.read!ubyte==0b101);
    r.close();
}
void testArrayByteWriter() {
    writefln("Testing ArrayByteWriter...");

    {
        auto w = new ArrayByteWriter;

        w.write!ubyte(0x89);
        assert(w.length==1 && w.getArray==[0x89]);

        w.write!ushort(0xd1d2);
        assert(w.length==3 && w.getArray==[0x89, 0xd2, 0xd1]);

        w.write!uint(0x01020304);
        assert(w.length==7 && w.getArray==[0x89, 0xd2, 0xd1, 4,3,2,1]);

        w.write!ulong(0x0102030405060708L);
        assert(w.length==15 && w.getArray==[0x89, 0xd2, 0xd1, 4,3,2,1, 8,7,6,5,4,3,2,1]);

        w.writeArray!ubyte(cast(ubyte[])[6,7,8]);
        assert(w.length==18 && w.getArray==[0x89, 0xd2, 0xd1, 4,3,2,1, 8,7,6,5,4,3,2,1, 6,7,8]);

        w.reset();
        assert(w.length==0);

        w.writeArray!ushort(cast(ushort[])[0x0304, 0x0506]);
        assert(w.length==4 && w.getArray==[4,3,6,5]);

        w.writeArray!uint([1,2]);
        assert(w.length==12 && w.getArray==[4,3,6,5, 1,0,0,0, 2,0,0,0]);

        w.pack();
        assert(w.length==12 && w.getReservedLength==12);

        w.writeArray!ulong([1]);
        assert(w.length==20 && w.getArray==[4,3,6,5, 1,0,0,0, 2,0,0,0, 1,0,0,0,0,0,0,0]);

        w.reset();
        assert(w.length == 0);

        w.write!float(3.14f);
        w.write!float(99f);
        w.writeArray!float([90f, 33f]);

        assert(w.getArray() == [195, 245, 72, 64, 0, 0, 198, 66, 0, 0, 180, 66, 0, 0, 4, 66]);

        w.reset();
        assert(w.length == 0);

        struct S {
            uint a; uint b;
        }
        S[] array = [S(1,2), S(3,4), S(5,6)];
        w.write!S(S(0,9));
        assert(w.getArray().as!(S*)[0] == S(0,9));
        w.reset();

        w.writeArray!S(array);
        assert(w.getArray.as!(S*)[0..3] == array);
    }
}
void testBitWriter() {
    writefln("--== Testing BitWriter ==--");

    ubyte[] received;

    void receiver(ubyte b) {
        writefln("%08b %02x", b, b);
        received ~= b;
    }

    auto writer = new BitWriter(&receiver);

    writer.write(0b11111111, 8);
    assert(received==[0xff]);
    assert(writer.bitsWritten==8);
    assert(writer.bytesWritten==1);

    writer.write(0b00001111, 4);
    assert(received==[0xff]);
    assert(writer.bitsWritten==12);
    assert(writer.bytesWritten==1);

    writer.write(0b00001111, 4);
    assert(received==[0xff, 0xff]);
    assert(writer.bitsWritten==16);
    assert(writer.bytesWritten==2);

    received.length = 0;
    writer.write(0b00001001, 4);
    assert(received==[]);
    assert(writer.bitsWritten==20);
    assert(writer.bytesWritten==2);

    writer.write(0b00001111, 4);
    assert(received==[0b11111001]);
    assert(writer.bitsWritten==24);
    assert(writer.bytesWritten==3);

    received.length = 0;
    writer.write(0b11111111, 7);
    assert(received==[]);
    assert(writer.bitsWritten==31);
    assert(writer.bytesWritten==3);

    writer.write(0b11111111, 1);
    assert(received==[0xff]);
    assert(writer.bitsWritten==32);
    assert(writer.bytesWritten==4);

    received.length = 0;
    writer.write(0b01, 2);
    writer.write(0b10, 2);
    writer.write(0b11, 2);
    writer.write(0b00, 2);
    assert(received==[0b00111001]);
    assert(writer.bitsWritten==40);
    assert(writer.bytesWritten==5);

    received.length = 0;
    writer.write(0xffffffff, 5);
    assert(writer.bitsWritten==45);
    assert(writer.bytesWritten==5);

    writer.flush();                 // 3 extra bits written
    assert(received==[0b11111]);
    assert(writer.bitsWritten==48);
    assert(writer.bytesWritten==6);

    received.length = 0;
    writer.write(0xffffffff, 3);
    writer.write(0, 2);
    writer.write(0xffffffff, 2);
    assert(writer.bitsWritten==55);
    assert(writer.bytesWritten==6);

    writer.flush();                 // 1 extra bit written
    assert(received==[0b1100111]);
    assert(writer.bitsWritten==56);
    assert(writer.bytesWritten==7);

    received.length = 0;
    writer.write(0xffffffff, 9);
    writer.write(0x01, 2);
    assert(writer.bitsWritten==67);
    assert(writer.bytesWritten==8);

    writer.flush();                 // 5 extra bits written
    assert(received==[0xff, 0b011]);
    assert(writer.bitsWritten==72);
    assert(writer.bytesWritten==9);

    writer.flush();                 // no change
    assert(writer.bitsWritten==72);
    assert(writer.bytesWritten==9);

    writer.write(0, 1);
    writer.flush();                 // flush 7 bits
    assert(writer.bitsWritten==80);
    assert(writer.bytesWritten==10);

    {
        auto bbw = new BufferBitWriter();
        assert(bbw.bitsWritten()==0);
        assert(bbw.bytesWritten()==0);
        assert(bbw.length()==0);
        assert(bbw.flushAndGetBuffer()==[]);

        bbw.write(0b1100, 4);
        assert(bbw.bitsWritten()==4);
        assert(bbw.bytesWritten()==0);

        bbw.write(0b0, 1);
        assert(bbw.bitsWritten()==5);
        assert(bbw.bytesWritten()==0);

        bbw.write(0b101, 3);
        assert(bbw.bitsWritten()==8);
        assert(bbw.bytesWritten()==1);
        assert(bbw.flushAndGetBuffer()==[0b10101100]);
        assert(bbw.bitsWritten()==8);
        assert(bbw.bytesWritten()==1);
    }
    {
        ubyte[] bytes;
        void receiver2(ubyte b) {
            bytes ~= b;
        }
        auto w = new BitWriter(&receiver2);
        w.writeOnes(0);
        assert(w.bitsWritten==0);
        w.writeOnes(1);
        assert(w.bitsWritten==1);
        w.writeOnes(7);
        assert(w.bitsWritten==8);
        assert(bytes == [cast(ubyte)0xff]);

        w.writeZeroes(0);
        assert(w.bitsWritten==8);
        w.writeZeroes(1);
        assert(w.bitsWritten==9);
        w.writeZeroes(7);
        assert(w.bitsWritten==16);
        assert(bytes == [cast(ubyte)0xff, 0]);

        w.writeOnes(40);
        assert(w.bitsWritten == 16+40);
        assert(bytes == [cast(ubyte)0xff, 0, 0xff,0xff,0xff,0xff,0xff]);

        w.writeZeroes(40);
        assert(w.bitsWritten == 16+40+40);
        assert(bytes == [cast(ubyte)0xff, 0, 0xff,0xff,0xff,0xff,0xff, 0,0,0,0,0]);

    }
}
void testBitReader() {
    writefln("--== Testing BitReader==--");

    ubyte[] bytes = [
        0b11111111, // [0]
        0b11110000, // [1]
        0b00001111, // [2]
        0b00110011, // [3]
        0b01010101, // [4]
        0b00100101, // [5]
        0b11111111, // [6]
        0b11111111, // [7]
        0b00110011  // [8]
    ];
    uint ptr;

    void reset() { ptr = 0; }
    ubyte byteProvider() {
        writefln("%08b %02x", bytes[ptr], bytes[ptr]);
        return bytes[ptr++];
    }

    {   // read
        auto r = new BitReader(&byteProvider);

        assert(0b11111111==r.read(8));
        assert(0b11110000==r.read(8));
        assert(0b00001111==r.read(8));
        assert(r.isAtStartOfByte);

        assert(0b0011==r.read(4) && !r.isAtStartOfByte);
        assert(0b0011==r.read(4) && r.isAtStartOfByte);

        assert(0b01==r.read(2) && !r.isAtStartOfByte);
        assert(0b01==r.read(2) && !r.isAtStartOfByte);
        assert(0b01==r.read(2) && !r.isAtStartOfByte);
        assert(0b01==r.read(2) && r.isAtStartOfByte);

        assert(0b1==r.read(1));
        assert(0b10==r.read(2));
        assert(0b100==r.read(3));
        assert(0b00==r.read(2) && r.isAtStartOfByte);
    }

    {   // skipToEndOfByte
        reset();
        auto r = new BitReader(&byteProvider);

        // bytes[0] = 0b11111111
        assert(1 == r.read(1));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[1] = 0b11110000
        assert(0==r.read(2));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[2] = 0b00001111
        assert(7==r.read(3));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[3] = 0b00110011
        assert(3==r.read(4));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[4] = 0b01010101
        assert(21==r.read(5));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[5] = 0b00100101
        assert(37==r.read(6));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[6] = 0b11111111
        assert(127==r.read(7));
        r.skipToEndOfByte();
        assert(r.isAtStartOfByte);

        // bytes[7] = 0b11111111
        assert(255==r.read(8));
        r.skipToEndOfByte();        // nothing skipped
        assert(r.isAtStartOfByte);

        // bytes[8] = 0b00110011
        assert(0b00110011==r.read(8) && r.isAtStartOfByte);
    }

    {
        writefln("FileBitReader");

        // create a temp file and write some bits to it
        string dir = tempDir();
        string filename = dir~uniform(0,100).to!string~"file.bin";
        scope f = File(filename, "wb");
        scope(exit) { f.close(); remove(filename); }

        auto writer = new FileBitWriter(filename);
        writer.write(0b1000, 4);
        writer.write(0b0101, 4);
        writer.write(0b11111, 5);
        writer.write(0b00111, 5);
        writer.write(0b11, 2);
        writer.write(0b010, 3);

        writer.close();

        // test the FileBitReader
        auto reader = new FileBitReader(filename);
        assert(reader.read(4)==0b1000);
        assert(reader.read(4)==0b0101);
        assert(reader.read(5)==0b11111);
        assert(reader.read(5)==0b00111);
        assert(reader.read(2)==0b11);
        assert(reader.read(3)==0b010);
        reader.close();
    }
}
void testBitReaderAndWriter() {
    writefln("--== Testing BitReader ==--");

    Mt19937 rng;
    rng.seed(unpredictableSeed);
    //rng.seed(1);
    uint[] bitValues;
    uint[] bitLengths;
    uint length = 1000;
    for(auto i=0; i<length; i++) {
        uint bl = uniform(0, 8, rng);
        uint bv = uniform(0, 1<<bl, rng);
        bitValues  ~= bv;
        bitLengths ~= bl;
    }
    writefln("bitValues  = %s", bitValues.map!(it=>"%2u".format(it)).join(", "));
    writefln("bitLengths = %s", bitLengths.map!(it=>"%2u".format(it)).join(", "));

    uint ptr;
    ubyte[] bytesWritten;
    ubyte getNextByte() {
        return bytesWritten[ptr++];
    }
    void byteWritten(ubyte b) {
        bytesWritten ~= b;
    }

    auto r = new BitReader(&getNextByte);
    auto w = new BitWriter(&byteWritten);

    for(auto i=0; i<length; i++) {
        w.write(bitValues[i], bitLengths[i]);
    }
    w.flush();

    writefln("bytesWritten = %s", bytesWritten);

    uint[] valuesRead;
    for(auto i=0; i<length; i++) {
        valuesRead ~= r.read(bitLengths[i]);
    }
    writefln("values     = %s", valuesRead.map!(it=>"%2u".format(it)).join(", "));

    assert(valuesRead==bitValues);
}
void testConsole() {
    writefln("Testing console...");
version(Win64) {
    /// Note: This needs to be run from an actual console not the IDE.

    scope(exit) Console.reset();

    Console.set(Console.Attrib.RED);
    writefln("red");

    Console.set(Console.Attrib.GREEN);
    writefln("green");
    Console.set(Console.Attrib.BLUE);
    writefln("blue");
    Console.set(Console.Attrib.YELLOW);
    writefln("yellow");
    Console.set(Console.Attrib.MAGENTA);
    writefln("magenta");
    Console.set(Console.Attrib.CYAN);
    writefln("cyan");
    Console.set(Console.Attrib.WHITE | Console.Attrib.UNDERSCORE);
    writefln("white");

    Console.set(Console.Attrib.BG_RED);
    writefln("red background");
    Console.set(Console.Attrib.BG_GREEN);
    writefln("green background");
    Console.set(Console.Attrib.BG_BLUE);
    writefln("blue background");
    Console.set(Console.Attrib.BG_YELLOW);
    writefln("yellow background");
    Console.set(Console.Attrib.BG_MAGENTA);
    writefln("magenta background");
    Console.set(Console.Attrib.BG_CYAN);
    writefln("cyan background");
}
}