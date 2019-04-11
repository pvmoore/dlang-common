module common.containers.PriorityQueue;

import common.all;
import std.traits : isEqualityComparable, isOrderingComparable;

auto makeHighPriorityQueue(T)() { return new PriorityQueue!(T, true); }
auto makeLowPriorityQueue(T)()  { return new PriorityQueue!(T, false); }
/**
 *  A priority queue implemented using a backing array. 
 *  This makes the assumtion that the size is not likely to get too large since shifting data in an
 *  array is likely to be faster than using a tree for small to medium sized queues due to cache locality.
 * 
 */
final class PriorityQueue(T,bool HI) : IQueue!T
    if(isOrderingComparable!T && isEqualityComparable!T)  
{
private:
    Array!T array;

    this() {
        array = new Array!T;
    }
public:
    bool empty() { return array.empty; }
    int length() { return array.length.as!int; }

    /**
     *  Returns the backing array in: 
     *      High priority queue -> lowest to highest priority order.
     *      Low priority queue  -> highest to lowest priority order.
     */
    T[] asArray() { return array[]; }

    /** 
     *  Inserts the value in priority order.
     */
    PriorityQueue!(T,HI) push(T value) {
        insert(value);
        return this;
    }
    /**
     *  When:
     *      High priority queue -> Pops the highest priority item.
     *      Low priority queue  -> Pops the lowest priority item.
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
    PriorityQueue!(T,HI) clear() {
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
            static if(HI) {
                array.insertAt(array.first() < value ? 1 : 0, value);
            } else {
                array.insertAt(value < array.first() ? 1 : 0, value);
            }
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
            } 
            static if(HI) {
                if(r > value) {
                    max = mid;
                } else {
                    min = mid+1;
                }
            } else {
                if(value > r) {
                    max = mid;
                } else {
                    min = mid+1;
                }
            }
        }
        array.insertAt(min, value);
    }
}