module common.containers.UnorderedMap;

import common.all;

/**
 * Associative array using linear probing.
 *
 * Faster than the built-in associative array in my testing.
 *
 * HASH: Ignore this template parameter. This sets the hash function to use for benchmarking.
 */
final class UnorderedMap(K, V, uint HASH = 0) {
public:
    this(ulong capacity = 16, float loadFactor = 0.75) {
        throwIf(!isPowerOf2(capacity), "capacity must be a power of 2");
        throwIf(loadFactor <= 0.0 || loadFactor > 1.0, "loadFactor must be > 0.0 and <= 1.0");

        this.loadFactor       = loadFactor;
        this.mask             = capacity - 1;

        this.slots.length     = capacity;
        this.flags.length     = capacity / 32 + 1;
        this.pageIndex.length = capacity;

        this.numKeysThreshold = calculateLoadFactorThreshold(capacity, loadFactor);

        addPage();
    }
    bool isEmpty() {
        return numKeys == 0;
    }
    ulong size() {
        return numKeys;
    }
    ulong capacity() {
        return slots.length;
    }
    /** 
     * Get a value from the map. Returns V.init if the key is not found
     * eg.
     *  auto v = map[key]
     */
    V opIndex(K key) {
        return get(key);
    }
    /** 
     * Add a Key,Value to the map
     * eg.
     *  map[key] = value
     */
    void opIndexAssign(V value, K key) {
        insert(key, value);
    }
    /** 
     * Add or replace a Key,Value in the map
     */
    void insert(K key, V value) {
        static if(isObject!K) assert(key !is null);
        uint slot = getSlot(key);

        // Find a free slot for this key. Or update the value in an existing slot
        while(true) {
            if(!isOccupied(slot)) {
                // This slot is free
                addKeyValue(slot, key, value);
                return;
            }

            // This slot is occupied

            if(slots[slot] == key) {
                // Update the value in this slot
                addValue(slot, value);
                return;
            }

            // Continue looping
            slot = nextSlot(slot);
        }
    }
    /** 
     * Get a value from the map. Returns defaultValue if the key is not found
     */
    V get(K key, V defaultValue = V.init) {
        static if(isObject!K) assert(key !is null);
        if(V* v = getPtr(key)) {
            return *v;
        }
        return defaultValue;
    }
    /** 
     * Get a pointer to a value from the map or null if the key is not found
     * The pointer is guaranteed to remain valid (even after rehashing or the map is deleted)
     */
    V* getPtr(K key) {
        static if(isObject!K) assert(key !is null);
        long slot = findSlotForKey(key);
        if(slot != -1) {
            return getValue(slot.as!uint);
        }
        return null;
    }
    /** 
     * Returns true if the key is in the map
     */
    bool containsKey(K key) {
        static if(isObject!K) assert(key !is null);
        return getPtr(key) !is null;
    }
    /** 
     * Remove a key from the map. Returns true if the key was found and removed
     */
    bool remove(K key) {
        static if(isObject!K) assert(key !is null);
        long foundSlot = findSlotForKey(key);
        if(foundSlot == -1) {
            // Key not found
            return false;
        }
        numKeys--;
        uint freeSlot = foundSlot.as!uint;
        setFree(freeSlot);

        // We need to adjust slots below this one until we find an unoccupied slot
        uint slot = nextSlot(freeSlot);
        uint distanceFromFreeSlot = 1;
        while(true) {
            if(isOccupied(slot)) {
                // If the key in this slot hashes to a slot that is equal to the free slot or before the free 
                // slot then we need to move it into the free slot. Repeat this process for the newly freed slot 
                // until we reach an unoccupied slot
                uint keySlot = getSlot(slots[slot]);
                long distance = slot.as!long - keySlot.as!long;
                distance = distance < 0 ? (distance + slots.length) : distance;

                if(distance >= distanceFromFreeSlot) {
                    // This key can be moved into the free slot
                    setOccupied(freeSlot);
                    slots[freeSlot] = slots[slot];
                    pageIndex[freeSlot] = pageIndex[slot];

                    // This slot is now the new free slot
                    setFree(slot);
                    freeSlot = slot;
                    distanceFromFreeSlot = 0;
                }

                // Keep looping
                slot = nextSlot(slot);
                distanceFromFreeSlot++; 
            } else {
                // This slot is unoccupied. We are done
                break;
            }
        }

        return true;
    }
    /** 
     * Add or replace a Key,Value in the map, applying one of the two mapping functions.
     *
     * params:
     *    createFunc: Function to call if the key is not found. Modify the value as required and
     *                then return true to add the value to the map.
     *                Note that the value ptr is not the canonical ptr to the value and should not be copied
     * 
     *    updateFunc: Function to call if the key is found. Modify the value as required
     *                then return true to update the value in the map or false to remove it
     *
     * Returns a pointer to the value in the map (or null if the key is no longer in the map)
     */
    V* compute(K key, bool delegate(K, V*) createFunc, bool delegate(K, V*) updateFunc) {
        static if(isObject!K) assert(key !is null);
        assert(createFunc !is null);
        assert(updateFunc !is null);

        long slot = findSlotForKey(key);
        if(slot == -1) {
            // Create the value (if required)
            V value;
            if(createFunc(key, &value)) {

                // Since we know that this key is not in the map we can just find the next free slot
                uint slot2 = getSlot(key);
                while(isOccupied(slot2)) {
                    slot2 = nextSlot(slot2);
                }
                // This slot is free
                return addKeyValue(slot2, key, value);
            }
            return null;
        } 
        // Update the value in the map
        V* valuePtr = getValue(slot.as!uint);
        if(updateFunc(key, valuePtr)) {
            return valuePtr;
        }
        remove(key);
        return null;
    }
    /** 
     * Return a new array containing all keys in the map (in undefined order)
     */
    K[] keys() {
        K[] result;
        foreach(slot; 0..slots.length.as!uint) {
            if(isOccupied(slot)) {
                result ~= slots[slot];
            }
        }
        return result;
    }
    /** 
     * Return a new array containing all values in the map (in undefined order)
     */
    V[] values() {
        V[] result;
        foreach(slot; 0..slots.length.as!uint) {
            if(isOccupied(slot)) {
                result ~= *getValue(slot);
            }
        }
        return result;
    }
    /** 
     * Return a range of keys (in undefined order).
     */
    auto byKey() {
        static struct Range {
            K[] keys;
            uint i;
            auto front() { return keys[i]; }
            bool empty() { return i >= keys.length; }
            void popFront() { i++; }
        }
        return Range(keys()); 
    }
    /** 
     * Return a range of values (in undefined order).
     */
    auto byValue() {
        static struct Range {
            V[] values;
            uint i;
            auto front() { return values[i]; }
            bool empty() { return i >= values.length; }
            void popFront() { i++; }
        }
        return Range(values()); 
    }
    /** 
     * Return a range of key,value entries (in undefined order).
     */
    auto byKeyValue() {
        static struct Entry {
            K key;
            V value;
        }
        static struct Range {
            K[] keys;
            V[] values;
            uint i;
            auto front() { return Entry(keys[i], values[i]); }
            bool empty() { return i >= keys.length; }
            void popFront() { i++; }
        }
        return Range(keys(), values()); 
    }
    /** 
     * Remove all keys from the map. Key memory is zeroed. 
     * Value memory is not affected. Capacity is not changed
     */
    void clear() {
        numKeys = 0;
        
        ubyte* ptr = slots.ptr.as!(ubyte*);
        ptr[0..slots.length * K.sizeof] = 0;
        
        flags[] = 0;
        pageIndex[] = 0;

        // Release the pages. The value pointers will still be valid if the client holds the pointer
        // but otherwise they will be garbage collected at some point 
        pages.length = 0;
        addPage();
    }
    /** 
     * Rehash the map to optimise memory usage or change the load factor
     */
    void rehash(ulong capacity, float loadFactor) {
        throwIf(!isPowerOf2(capacity), "capacity must be a power of 2");
        throwIf(loadFactor <= 0.0 || loadFactor > 1.0, "loadFactor must be > 0.0 and  <= 1.0");
        todo("not implemented");
        // Here we can rehash the keys if the capacity is too large
        // Also, we can reorganise the value data which may contain empty pages 
    }
    void dump() {
        foreach(slot; 0..slots.length.as!uint) {
            V value = *getValue(slot);
            string f = "%s".format(isOccupied(slot) ? "O" : "-");
            string s = isOccupied(slot) ? "%s = %s".format(slots[slot], value) : "";

            writefln("[%2s %s] %s", slot, f, s);
        }
        writefln("size = %s/%s, pages = %s, load = %.2f, threshold = %s", size(), slots.length, 
            pages.length, numKeys.as!float / slots.length, numKeysThreshold);
    }
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:
    float loadFactor;       // Desired max load factor. Default is 0.75
    ulong numKeys;          // Current number of keys in the map
    ulong mask;             // slots.length - 1
    uint numKeysThreshold;  // numKeys value which will trigger a rehash 

    // These are all related to the number of key slots (capacity). They are separated 
    // because it is faster to access them in this data oriented way rather than putting them
    // all into an array of structs
    K[] slots;              // slots.length is current capacity
    uint[] flags;           // Bit flags for keySlots. 1 = occupied, 0 = free
    ulong[] pageIndex;      // (page<<32 | index) for each slot value

    // These are related to value storage
    int pagePointer;
    Page[] pages;
    
    static struct Page {
        V[] array;
    }

    V* addKeyValue(uint slot, K key, V value) {
        // This will also set the page and index in _slot_
        V* valuePtr = addValue(slot, value);        

        numKeys++;
        setOccupied(slot);
        slots[slot] = key;

        if(numKeys >= numKeysThreshold) {
            expand();
        }

        return valuePtr;
    }
    V* addValue(uint slot, V value) {
        assert(pages.length > 0);

        pagePointer++;
        if(pagePointer >= pages[$-1].array.length) {
            addPage();
            pagePointer = 0;
        }
        ulong page = pages.length - 1;

        // Update the slot page|index data
        pageIndex[slot] = (page << 32) | pagePointer;  

        V* ptr = &pages[page].array[pagePointer];
        *ptr = value;
        return ptr;
    }
    V* getValue(uint slot) {
        ulong page = pageIndex[slot] >>> 32;
        ulong index = pageIndex[slot] & 0xFFFF_FFFF;
        assert(page < pages.length);
        assert(index < pages[page].array.length);
        return &pages[page].array[index];
    }
    void addPage() {
        assert(slots.length > 0);
        // Maximum page array length is 1M values for no particular reason
        const maxLength = 1024*1024;
        auto length = slots.length < maxLength ? slots.length : maxLength;
        pagePointer = -1;
        pages ~= Page(new V[length]);
    }

    bool isOccupied(uint slot) {
        uint u = slot >>> 5;
        uint r = slot & 31;
        return ((flags[u] >>> r) & 1) == 1;
    }
    void setOccupied(uint slot) {
        uint u = slot >>> 5;
        uint r = slot & 31;
        flags[u] |= (1 << r);
    }
    void setFree(uint slot) {
        uint u = slot >>> 5;
        uint r = slot & 31;
        flags[u] &= ~(1 << r);
    }
    /** Get the next slot, wrapping around if necessary */
    uint nextSlot(uint slot) {
        return (slot+1) & mask;
    }
    uint getSlot(K key) {
        return (getHash(key) & mask).as!uint;
    }
    /**
     * Find the slot for a given key
     * Returns -1 if not found
     */
    long findSlotForKey(K key) {
        uint slot = getSlot(key);

        while(isOccupied(slot) && slots[slot] != key) {
            slot = nextSlot(slot);
        }
        return isOccupied(slot) ? slot : -1L;
    }
    ulong getHash(K key) {
        // Call toHash if K implements it
        static if(__traits(compiles, key.toHash())) {
            ulong hash = key.toHash();
        } else static if(is(K : ulong)) {
            // All integer types should use this hash
            ulong hash = ulongHash(key);
        } else static if(is(K==string)) {
            ulong hash = djb2_hash(key);
        } else {
            // todo - We could hash the raw bytes of this type here instead
            TypeInfo t = typeid(typeof(key));
            ulong hash = t.getHash(&key);
        }
        return hash;
    }
    ulong ulongHash(ulong key) {
        static if(HASH == 0) {
            ulong hash = hash0(key);
        } else static if(HASH == 1) {
            ulong hash = hash1(key);
        } else static if(HASH == 2) {
            ulong hash = hash2(key);
        } else static if(HASH == 3) {
            ulong hash = hash3(key);
        } else static if(HASH == 4) {
            ulong hash = hash4(key);
        } else static if(HASH == 5) {
            ulong hash = hash5(key);
        } else static assert(false);
        return hash;
    }
    static uint calculateLoadFactorThreshold(ulong capacity, float loadFactor) {
        ulong threshold = (capacity * loadFactor).as!uint;
        if(threshold == 0) {
            threshold = 1;
        }
        if(threshold > capacity) {
            threshold = capacity;
        }
        return threshold.as!uint;
    }

    /**
     * Double the capacity of the map.
     */
    void expand() {
        K[] oldSlots         = slots;
        uint[] oldFlags      = flags;
        ulong[] oldPageIndex = pageIndex;
        auto length          = slots.length *2;

        this.mask             = length - 1;
        this.slots            = new K[length];
        this.flags            = new uint[length / 32 + 1];
        this.pageIndex        = new ulong[length];
        this.numKeysThreshold = calculateLoadFactorThreshold(length, loadFactor);

        uint u   = 0;
        uint bit = 1;
        uint f   = oldFlags[u];

        foreach(oldSlot; 0..oldSlots.length) {
            if(f & bit) {
                uint newSlot = getSlot(oldSlots[oldSlot]);
                while(isOccupied(newSlot)) newSlot = nextSlot(newSlot);

                setOccupied(newSlot);
                slots[newSlot]     = oldSlots[oldSlot];
                pageIndex[newSlot] = oldPageIndex[oldSlot];
            }

            bit <<= 1;
            if(!bit) {
                u++;
                bit = 1;
                f = oldFlags[u];
            }
        }
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

// https://en.wikipedia.org/wiki/List_of_hash_functions#Non-cryptographic_hash_functions

// hash0 and hash3 seem to be the best ones

ulong hash0(ulong x) {
    x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9L;
    x = (x ^ (x >> 27)) * 0x94d049bb133111ebL;
    x = x ^ (x >> 31);
    return x;
}
ulong hash1(ulong key) {
  key = (~key) + (key << 21); 
  key = key ^ (key >>> 24);
  key = (key + (key << 3)) + (key << 8); 
  key = key ^ (key >>> 14);
  key = (key + (key << 2)) + (key << 4); 
  key = key ^ (key >>> 28);
  key = key + (key << 31);
  return key;
}
ulong hash2(ulong key) {
    key = (~key) + (key << 18); 
    key = key ^ (key >>> 31);
    key = key * 21; 
    key = key ^ (key >>> 11);
    key = key + (key << 6);
    key = key ^ (key >>> 22);
    return key;
}
// This one seems to be the best
ulong hash3(ulong key) {
    return (hash2a((key >>> 32).as!uint).as!ulong << 32) | hash2a(key.as!uint);
}
ulong hash4(ulong key) {
    return (hash3a((key >>> 32).as!uint).as!ulong << 32) | hash3a(key.as!uint);
}
ulong hash5(ulong key) {
    return hash0(key) ^ hash3(key);
}

uint hash2a(uint x) {
    x ^= x >> 16;
    x *= 0x7feb352d;
    x ^= x >> 15;
    x *= 0x846ca68b;
    x ^= x >> 16;
    return x;
}
uint hash3a(uint a) {
   a = (a+0x7ed55d16) + (a<<12);
   a = (a^0xc761c23c) ^ (a>>19);
   a = (a+0x165667b1) + (a<<5);
   a = (a+0xd3a2646c) ^ (a<<9);
   a = (a+0xfd7046c5) + (a<<3);
   a = (a^0xb55a4f09) ^ (a>>16);
   return a;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
ulong djb2_hash(string s) {
    ulong hash = 5381;
    foreach(c; s) {
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
    }
    return hash;
}
