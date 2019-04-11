module common.containers.PriorityQueue;

import common.all;
import std.traits : isEqualityComparable, isOrderingComparable;
/**
 *  
 */
final class PriorityQueue(T) : IQueue!T
    if(isOrderingComparable!T && isEqualityComparable!T)  
{
private:
    // Hold values from lowest to highest priority 
    Array!T array;
public:
    this() {
        array = new Array!T;
    }
    bool empty() { return array.empty; }
    int length() { return array.length.as!int; }

    /**
     *  Returns array in lowest to highest priority order.
     */
    T[] asArray() { return array[]; }

    /** 
     *  
     */
    PriorityQueue!T push(T value) {
        insert(value);
        return this;
    }
    /**
     *  Pop() is always a O(1) operation.
     */
    T pop() {
        assert(!empty);
        return array.removeAt(array.length-1);
    }
    uint drain(T[] array) {
        todo();
        return 0;
    }
    PriorityQueue!T clear() {
        array.clear();
        return this;
    }
private:
    void insert(T value) {
        if(array.length==0) { 
            array.add(value);
            return;
        } 
        if(array.length==1) {
            array.insertAt(array.first() < value ? 1 : 0, value);
            return;
        } 

        ulong min = 0;
        ulong max = array.length;
        while(min<max) {
            auto mid = (min+max)>>1;
            auto r   = array[mid];

            if(r==value) {
                array.insertAt(mid, value);
                return;
            } else if(r > value) {
                max = mid;
            } else {
                min = mid+1;
            }
        }
        array.insertAt(min, value);
    }
}