module common.containers.Set;

import common.all;
import common.containers;
private import common.containers.containers_internal;

final class Set(K) {
public:
    this(ulong capacity = 16, float loadFactor = 0.75) {
        throwIf(!isPowerOf2(capacity), "capacity must be a power of 2");
        throwIf(loadFactor <= 0.0 || loadFactor > 1.0, "loadFactor must be > 0.0 and <= 1.0");

        this.loadFactor       = loadFactor;
        this.numKeys          = 0;
        this.mask             = capacity - 1;
        this.numKeysThreshold = calculateLoadFactorThreshold(capacity, loadFactor);

        this.slots.length = capacity;
        this.flags.length = capacity / 32 + 1;
    }
    bool isEmpty() const {
        return numKeys == 0;
    }
    ulong size() const {
        return numKeys;
    }
    ulong capacity() const {
        return slots.length;
    }
    void clear() {
        this.numKeys = 0;
        this.flags[] = 0;

        // Zero the key slots
        import core.stdc.string : memset;
        memset(slots.ptr, 0, slots.length * K.sizeof);
    }
    void add(K key) {
        static if(isObject!K) assert(key !is null);

        uint slot = getSlot(key);

        // Find a free slot for this key. Or update the value in an existing slot
        while(true) {
            if(!isOccupied(slot)) {
                // This slot is free
                addKey(slot, key);
                return;
            }

            // This slot is occupied

            if(slots[slot] == key) {
                // This key is already in the map
                return;
            }

            // Continue looping
            slot = nextSlot(slot);
        }
    }
    void add(K[] keys) {
        foreach(key; keys) {
            add(key);
        }
    }
    void add(Set!K other) {
        if(other is null) return;
        foreach(i; 0..other.slots.length.as!uint) {
            if(other.isOccupied(i)) {
                add(other.slots[i]);
            }
        }
    }
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
    bool contains(K key) const {
        static if(isObject!K) assert(key !is null);
        return findSlotForKey(key) != -1;
    }
    /** 
     *  Returns true if the key is in the map.
     *  bool v = map[key]
     */
    bool opIndex(K key) const {
        return contains(key);
    }
    /** 
     * Add or remove a Key from the map
     * eg.
     *  map[key] = true | false;
     */
    void opIndexAssign(bool value, K key) {
        static if(isObject!K) assert(key !is null);
        if(value) {
            add(key);
        } else {
            remove(key);
        }
    }
    /** 
     * Add or replace a Key in the map, applying one of the two mapping functions.
     *
     * params:
     *    createFunc: Function to call if the key is not found. 
     *                Return true to add the value to the map or false to not add it.
     * 
     *    updateFunc: Function to call if the key is found. 
     *                Return true to keep the key in the map or false to remove it
     *
     * Returns true if the key is in the map at the end of the compute operation
     */
    bool compute(K key, bool delegate(K) createFunc, bool delegate(K) updateFunc) {
        static if(isObject!K) assert(key !is null);
        assert(createFunc !is null);
        assert(updateFunc !is null);

        long slot = findSlotForKey(key);
        if(slot == -1) {
            // Create 
            if(createFunc(key)) {

                // Add the key

                // Since we know that this key is not in the map we can just find the next free slot
                uint slot2 = getSlot(key);
                while(isOccupied(slot2)) {
                    slot2 = nextSlot(slot2);
                }
                // This slot is free
                addKey(slot2, key);
                return true;
            }
            return false;
        } 
        // Update 
        if(updateFunc(key)) {
            return true;
        }
        remove(key);
        return false;
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
     * Return a range of keys (in undefined order).
     */
    auto byKey() {
        static struct SetRange {
            K[] keys;
            uint i;
            auto front() { return keys[i]; }
            bool empty() { return i >= keys.length; }
            void popFront() { i++; }
        }
        return SetRange(keys()); 
    }
    override string toString() const {
        return "Set!%s(size:%s)".format(K.stringof, size());
    }
    void dump() {
        foreach(slot; 0..slots.length.as!uint) {
            string f = "%s".format(isOccupied(slot) ? "O" : "-");
            string s = isOccupied(slot) ? "%s".format(slots[slot]) : "";

            writefln("[%2s %s] %s", slot, f, s);
        }
        writefln("size = %s/%s, load = %.2f, threshold = %s", size(), slots.length, 
             numKeys.as!float / slots.length, numKeysThreshold);
    }
private:
    float loadFactor;       // Desired max load factor. Default is 0.75
    ulong numKeys;          // Current number of keys in the map
    ulong mask;             // slots.length - 1
    uint numKeysThreshold;  // numKeys value which will trigger a rehash 

    K[] slots;              // Keys
    uint[] flags;           // Occupancy flags 

    bool isOccupied(uint slot) const {
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
    uint nextSlot(uint slot) const {
        return (slot+1) & mask;
    }
    uint getSlot(K key) const {
        return (getHash(key) & mask).as!uint;
    }
    ulong getHash(K key) const {
        // Call toHash if K implements it
        static if(__traits(compiles, key.toHash())) {
            ulong hash = key.toHash();
        } else static if(is(K : ulong)) {
            // All integer types should use this hash
            ulong hash = hash3(key);
        } else static if(is(K==string)) {
            ulong hash = djb2_hash(key);
        } else {
            // todo - We could hash the raw bytes of this type here instead
            TypeInfo t = typeid(typeof(key));
            ulong hash = t.getHash(&key);
        }
        return hash;
    }
    void addKey(uint slot, K key) {
        numKeys++;
        setOccupied(slot);
        slots[slot] = key;

        if(numKeys >= numKeysThreshold) {
            expand();
        }
    }
    /**
     * Find the slot for a given key
     * Returns -1 if not found
     */
    long findSlotForKey(K key) const {
        uint slot = getSlot(key);

        while(isOccupied(slot) && slots[slot] != key) {
            slot = nextSlot(slot);
        }
        return isOccupied(slot) ? slot : -1L;
    }
    /**
     * Double the capacity of the map.
     */
    void expand() {
        K[] oldSlots         = slots;
        uint[] oldFlags      = flags;
        auto length          = slots.length * 2;

        this.mask             = length - 1;
        this.slots            = new K[length];
        this.flags            = new uint[length / 32 + 1];
        this.numKeysThreshold = calculateLoadFactorThreshold(length, loadFactor);

        uint u   = 0;
        uint bit = 1;
        uint f   = oldFlags[u];

        foreach(oldSlot; 0..oldSlots.length) {
            if(f & bit) {
                uint newSlot = getSlot(oldSlots[oldSlot]);
                while(isOccupied(newSlot)) newSlot = nextSlot(newSlot);

                setOccupied(newSlot);
                slots[newSlot] = oldSlots[oldSlot];
            }

            bit <<= 1;
            if(!bit) {
                u++;
                bit = 1;
                f = oldFlags[u];
            }
        }
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
}
