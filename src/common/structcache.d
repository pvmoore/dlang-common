module common.structcache;

import common.all;

/**
 *  Memory cache providing pinned memory for structs.
 *
 */
final class StructCache(T) if(is(T == struct)) {
private:
    int ELEMENT_SIZE;
    MemBlock[] blocks;
    int len;

    class MemBlock {
        ubyte[] buffer;
        int[] freeList;
        int head;
        int len;

        this(int size) {
            buffer.length   = size*ELEMENT_SIZE;
            freeList.length = size;
            reset();
        }
        bool isFull() const { return len==freeList.length; }
        bool isEmpty() const { return len==0; }
        T* take() {
            ubyte* p    = buffer.ptr;
            uint offset = head*ELEMENT_SIZE;
            head        = freeList[head];
            T* ptr      = cast(T*)(p+offset);
            len++;
            return ptr;
        }
        void release(T* ptr) {
            ubyte* p   = cast(ubyte*)ptr;
            auto diff  = cast(ptrdiff_t)(p-buffer.ptr);
            auto index = cast(int)(diff/ELEMENT_SIZE);
            freeList[index] = head;
            head = index;
            len--;
        }
        void reset() {
            head = len = 0;
            for(auto i=0; i<freeList.length; i++) {
                freeList[i] = i+1;
            }
        }
    }
public:
    @property int length() const { return len; }

    override string toString() {
        auto buf = appender!(string[]);
        buf ~= "[StructCache length=%s #blocks=%s] {"
            .format(len, blocks.length);
        foreach(m; blocks) {
            char[] s = cast(char[])("O".repeat(m.freeList.length));

            uint h = m.head;
            while(h<m.freeList.length) {
                s[h] = '-';
                h = m.freeList[h];
            }
            buf ~= ("\t"~cast(string)s);
        }
        buf ~= "}";
        return buf.data.join("\n");
    }

    this(int initialNumElements, int alignment=1) {
        calculateElementSize(alignment);
        addMemBlock(initialNumElements);
    }
    T* take() {
        auto b   = findFreeMemBlock();
        auto ptr = b.take();
        len++;
        return ptr;
    }
    void release(T* t) {
        long index;
        auto b = findMemBlock(t, &index);
        b.release(t);
        len--;

        if(blocks.length>1 &&
           b.isEmpty() &&
           countEmptyMemBlocks()>1)
        {
            // release a block if 2 of them are empty
            releaseSmallestFreeMemBlock();
        }
    }
    void releaseAll() {
        len = 0;
        foreach(b; blocks) {
            b.reset();
        }
        while(blocks.length>1) {
            releaseSmallestFreeMemBlock();
        }
    }
private:
    MemBlock findFreeMemBlock() {
        foreach(i, m; blocks) {
            if(!m.isFull()) return m;
        }
        return addMemBlock(cast(int)blocks[$-1].freeList.length*2);
    }
    MemBlock findMemBlock(T* ptr, long* index) {
        ptrdiff_t p = cast(ptrdiff_t)ptr;
        foreach(i, m; blocks) {
            ptrdiff_t base = cast(ptrdiff_t)m.buffer.ptr;
            ptrdiff_t max  = base+m.buffer.length;
            if(p>=base && p<max) {
                *index = i;
                return m;
            }
        }
        throwIf(true);
        assert(false);
    }
    void calculateElementSize(int alignment) {
        alignment--;
        ELEMENT_SIZE = cast(int)(alignment==0 ? T.sizeof :
            (T.sizeof + alignment) & ~alignment);
    }
    MemBlock addMemBlock(int size) {
        auto b = new MemBlock(size);
        blocks ~= b;
        return b;
    }
    int countEmptyMemBlocks() {
        int count = 0;
        foreach(m; blocks) {
            if(m.isEmpty()) count++;
        }
        return count;
    }
    void releaseSmallestFreeMemBlock() {
        long smallestIndex = 0;
        long smallestLen   = int.max;
        foreach(i, m; blocks) {
            if(m.isEmpty() && m.freeList.length < smallestLen) {
                smallestIndex = i;
                smallestLen   = m.freeList.length;
            }
        }
        //writefln("removing empty block %s", smallestIndex);
        blocks.removeAt(smallestIndex);
    }
}

