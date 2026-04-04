module common.allocators.ContiguousFreeList;

import common.all;

/** 
 *  A free list for memory that needs to be allocated as a contiguous block for eg. GPU data.     
 *  This does not mean it is ordered, only that there will be no unallocated holes.
 *  Released slots are filled by swapping in the contents of the last slot and the Handle
 *  table adjusted so that values allocated at each Handle still point to the same data.
 *  A callback is called in most cases after release() is called so that the user can keep the data in sync.
 * 
 *  Example callback:
 *    void delegate(uint from, uint to) callback = (from, to) {
 *        mydata[to] = mydata[from];
 *    };
 *
 *  Always use the getIndex(handle) method to access the data elements.
 *
 *  eg.
 *    ContiguousFreeList list = new ContiguousFreeList(8, callback);
 *    auto handle = list.acquire();
 *    uint dataIndex = list.getIndex(handle);   // Get the actual data element index
 *    mydata[dataIndex] = value;                // Update the data
 *    list.release(handle);
 */
final class ContiguousFreeList {
public: 
    struct Handle {
        const uint id;

        string toString() {
            return "Handle(%s)".format(id);
        }
    }

    uint numUsed() { return length; }
    uint numFree() { return maxLength - length; }
    uint size() { return maxLength; }

    this(uint maxLength, void delegate(uint from, uint to) dataMoveCallback) {
        this.dataMoveCallback = dataMoveCallback;
        this.maxLength = maxLength;
    }       
    
    void reset() {
        handleToIndex.length = 0;
        indexToHandle.length = 0;
        length = 0;
    }

    /**
     *  Get the data index for a Handle. This should be called each time the index is required unless
     *  you know that release() has not been called in between as this could change the index.
     */
    uint getIndex(Handle h) {
        return handleToIndex[h.id];
    }

    /** 
     * Acquire a free element. 
     * @returns a Handle that can be used to access the data. Call getDataIndex(handle) to get the index.
     */
    Handle acquire() {
        throwIf(numUsed() == size(), "ContiguousFreeList is full"); 

        assert(handleToIndex.length < size());
        assert(indexToHandle.length < size());

        uint slot;

        // Expand the index tables if we are at the end
        if(indexToHandle.length == length) {
            indexToHandle ~= length.as!uint;
            handleToIndex ~= length.as!uint;
            slot = length;
        } else {
            slot = indexToHandle[length];
        }

        length++;
        return Handle(slot);
    }
    /** 
     * Release a Handle. Data will be swapped from the last position to the freed slot and the ID table adjusted.
     */
    void release(Handle handle) {
        assert(numUsed() > 0, "ContiguousFreeList is empty");

        uint a = getIndex(handle);
        uint b = --length;

        if(a!=b) {
            uint c = indexToHandle[a];
            uint d = indexToHandle[b];

            swap(handleToIndex[c], handleToIndex[d]);
            swap(indexToHandle[a], indexToHandle[b]);
        }
        // Inform the caller that the data has moved from data[b] to data[a]
        // Note that a == b is possible if the index is at the end. Notify the caller anyway
        // because they may be interested even if they don't want to move the data
        dataMoveCallback(b, a);
    }
    override string toString() {
        string s = "ContiguousFreeList (used %s, free %s) {".format(numUsed(), numFree());
        s ~= "\n  handleToIndex : %s".format(handleToIndex);
        s ~= "\n  indexToHandle : %s".format(indexToHandle);
        return s ~ "\n}";
    }
    
private:
    void delegate(uint from, uint to) dataMoveCallback;
    const uint maxLength;

    uint length;
    uint[] handleToIndex;
    uint[] indexToHandle;
}
