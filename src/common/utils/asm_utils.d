module common.utils.asm_utils;

import common.all;

private:

__gshared float f1,f2,f3,f4,f5,f6,f7,f8;

public:

/**
 *  128 bit AVX
 */
void dumpXMMfloat(int index) {
	asm pure nothrow {
		// rcx = index
		lea RDX, f1;

        dec ECX;
        jns _1;
        movups [RDX], XMM0;
        jmp _end;
_1:		dec ECX;
        jns _2;
        movups [RDX], XMM1;
        jmp _end;
_2:		dec ECX;
        jns _3;
        movups [RDX], XMM2;
        jmp _end;
_3:		dec ECX;
        jns _4;
        movups [RDX], XMM3;
        jmp _end;
_4:		dec ECX;
        jns _5;
        movups [RDX], XMM4;
        jmp _end;
_5:		dec ECX;
        jns _6;
        movups [RDX], XMM5;
        jmp _end;
_6:		dec ECX;
        jns _7;
        movups [RDX], XMM6;
        jmp _end;
_7:		dec ECX;
        jns _8;
        movups [RDX], XMM7;
        jmp _end;
_8:		dec ECX;
        jns _9;
        movups [RDX], XMM8;
        jmp _end;
_9:		dec ECX;
        jns _10;
        movups [RDX], XMM9;
        jmp _end;
_10:	dec ECX;
        jns _11;
        movups [RDX], XMM10;
        jmp _end;
_11:	dec ECX;
        jns _12;
        movups [RDX], XMM11;
        jmp _end;
_12:	dec ECX;
        jns _13;
        movups [RDX], XMM12;
        jmp _end;
_13:	dec ECX;
        jns _14;
        movups [RDX], XMM13;
        jmp _end;
_14:	dec ECX;
        jns _15;
        movups [RDX], XMM14;
        jmp _end;
_15:	dec ECX;
        jns _end;
        movups [RDX], XMM15;
_end:;
	}
   	writefln("[XMM%2s] %12s %12s %12s %12s", index, f1, f2, f3, f4);
}

version(DigitalMars) {
/**
 *  256 bit AVX2
 */
void dumpYMMfloat(int index) {
	asm pure nothrow {
		// rcx = index
		lea RDX, f1;

        dec ECX;
        jns _1;
        vmovups [RDX], YMM0;
        jmp _end;
_1:		dec ECX;
        jns _2;
        vmovups [RDX], YMM1;
        jmp _end;
_2:		dec ECX;
        jns _3;
        vmovups [RDX], YMM2;
        jmp _end;
_3:		dec ECX;
        jns _4;
        vmovups [RDX], YMM3;
        jmp _end;
_4:		dec ECX;
        jns _5;
        vmovups [RDX], YMM4;
        jmp _end;
_5:		dec ECX;
        jns _6;
        vmovups [RDX], YMM5;
        jmp _end;
_6:		dec ECX;
        jns _7;
        vmovups [RDX], YMM6;
        jmp _end;
_7:		dec ECX;
        jns _8;
        vmovups [RDX], YMM7;
        jmp _end;
_8:		dec ECX;
        jns _9;
        vmovups [RDX], YMM8;
        jmp _end;
_9:		dec ECX;
        jns _10;
        vmovups [RDX], YMM9;
        jmp _end;
_10:	dec ECX;
        jns _11;
        vmovups [RDX], YMM10;
        jmp _end;
_11:	dec ECX;
        jns _12;
        vmovups [RDX], YMM11;
        jmp _end;
_12:	dec ECX;
        jns _13;
        vmovups [RDX], YMM12;
        jmp _end;
_13:	dec ECX;
        jns _14;
        vmovups [RDX], YMM13;
        jmp _end;
_14:	dec ECX;
        jns _15;
        vmovups [RDX], YMM14;
        jmp _end;
_15:	dec ECX;
        jns _end;
        vmovups [RDX], YMM15;
_end:;
	}
   	writefln("[YMM%2s] %12s %12s %12s %12s %12s %12s %12s %12s",
       index, f1, f2, f3, f4, f5, f6, f7, f8);
}

} // version(DigitalMars)