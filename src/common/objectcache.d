module common.objectcache;

import common.all;
/**
 * Container for new instances of a class or interface.
 *
 * If T does not have a default constructor or
 * is not a concrete class then the
 * cache needs to be pre-populated with instances
 * otherwise a default instance will be created
 * on demand.
 */
final class ObjectCache(T)
if(is(T == class) || is(T == interface))
{
private:
    Stack!T available;
public:
    this() {
        available = new Stack!T(8);
    }
    @property auto numAvailable() const { return available.length; }

    T take() {
        if(available.length>0) {
            return available.pop();
        }
        static if(__traits(compiles, new class T{})) {
            return new class T{};
        } else {
            throw new Error("ObjectCache exhausted");
        }
    }
    void release(T t) {
        available.push(t);
    }
}


