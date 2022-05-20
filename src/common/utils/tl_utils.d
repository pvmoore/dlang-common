module common.utils.tl_utils;

import common.stringbuffer;

private {
    // Thread locals
    StringBuffer _tlStringBuffer;
}

public:

StringBuffer tlStringBuffer() {
    if(!_tlStringBuffer) {
        _tlStringBuffer = new StringBuffer();
    }
    _tlStringBuffer.clear();
    return _tlStringBuffer;
}