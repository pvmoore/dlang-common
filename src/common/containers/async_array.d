module common.containers.async_array;
/**
 * Naive/slow implementation of an asynchronous array.
 */
import common.all;

final class AsyncArray(T) {
private:
    T[] array;
    uint len;
    Mutex lock;
public:
    this() {
        this.lock = new Mutex;
    }
    @Async uint length() {
        return len;
    }
    @Async bool empty() { return len==0; }


    @Async override string toString() {
        lock.lock();
        scope(exit) lock.unlock();

        return "[]";
    }
    @Async T opIndex(ulong i) {
        lock.lock();
        scope(exit) lock.unlock();

        return array[i];
    }
    @Async bool opEquals(T[] o) {
        lock.lock();
        scope(exit) lock.unlock();

        if(len!=o.length) return false;
        return array[0..len] == o;
    }
    @Async auto add(T value) {
        lock.lock();
        scope(exit) lock.unlock();

        expand(1);
        array[len++] = value;

        return this;
    }
    @Async T remove(ulong index) {
        lock.lock();
        scope(exit) lock.unlock();

        T val = array[index];
	    len--;

        static if(__traits(isPOD,T)) {
            memmove(
                array.ptr+index,        // dest
                array.ptr+index+1,      // src
                (len-index)*T.sizeof);  // num bytes
        } else {
            for(auto j = index; j<len; j++) {
                array[j] = array[j+1];
            }
        }
	    return val;
    }
private:
    @Async void expand(long count) {
        if(len+count >= array.length) {
            auto newLength = (len+count+1)*2;
            array.length = newLength;
        }
    }
}

