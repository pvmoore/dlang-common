module common.utils.async_utils;

import common.all;
import core.thread  : Thread, ThreadID;
import core.atomic  : atomicOp, atomicLoad, atomicStore, cas;

struct AssertSingleThreaded {
private:
    shared ThreadID savedThreadId = -1;
public:
    void check() {
        version(assert) {
            auto id     = Thread.getThis().id;
            auto prevId = atomicLoad(savedThreadId);

            if(prevId==-1) {
                atomicStore(savedThreadId, id);
            } else {
                assert(id == prevId, "Second thread detected in single threaded code");
            }
        }
    }
}
