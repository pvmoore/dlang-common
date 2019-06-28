module common.wasm;

public:

import common.wasm.json;

/**
 *  Some simple c-lib functions which are not available in wasm:
 */

void* memcpy(void* dest, void* src, int size) {
    auto d = cast(ubyte*)dest;
    auto s = cast(ubyte*)src;
    for(auto i=0; i<size; i++) {
        *d++ = *s++;
    }
    return dest;
}
void* memset(void* ptr, int val, int size) {
    ubyte* dest = cast(ubyte*)ptr;
    ubyte c     = cast(ubyte)val;
    for(auto i=0; i<size; i++) {
        *dest++ = c;
    }
    return ptr;
}
int memcmp(ubyte* ptr1, ubyte* ptr2, uint numBytes) {
    for(auto i=0; i<numBytes; i++) {
        if(ptr1[i] < ptr2[i]) return -1;
        if(ptr1[i] > ptr2[i]) return 1;
    }
    return 0;
}
void zeroMem(T)(T* ptr, int count) {
    for(auto i=0; i<count; i++) {
        *ptr++ = 0;
    }
}
// Only handles positive integers
uint powi(int n, uint power) {
    if(power==0) return 1;
    if(power==1) return n;

    for(auto i=0; i<power-1; i++) {
        n *= n;
    }
    return n;
}
// Return the int representation of the string in _str_ of length _len_
int stringToInt(inout char* str, int len) {
    int r = 0;
    int mul = powi(10, len-1);
    for(auto i=0; i<len; i++) {
        int ch = (str[i] - '0') * mul;
        r += ch;
        mul /= 10;
    }
    return r;
}
// Assume the buffer is at least 32 bytes
int intToString(int n, char* buffer) {
    if(n==0) {
        buffer[0] = '0';
        return 1;
    }
    int pos = 0;
    while(n) {
        auto r = (n%10) + '0';
        n /= 10;
        buffer[pos++] = cast(char)r;
    }
    if(pos>1) {
        // reverse the buffer
        ubyte[32] temp;
        memcpy(temp.ptr, buffer, pos);
        for(auto i=pos-1; i>=0; i--) {
            *buffer++ = temp[i];
        }
    }
    return pos;
}