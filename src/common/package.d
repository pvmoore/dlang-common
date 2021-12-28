module common;

version(X86_64) {} else { pragma(msg,"64 bit required"); static assert(false); }
version(D_InlineAsm_X86_64) {} else { pragma(msg,"Inline assembler required"); static assert(false); }

public:

import common.allocator;
import common.archive;
import common.boxing;
import common.attributes;
import common.bool3;
import common.FreeList;
import common.hasher;
import common.intrinsics;
import common.objectcache;
import common.optional;
import common.pinned_array;
import common.Sequence;
import common.stringbuffer;
import common.structcache;
import common.velocity;

version(Win64) {
    import common.pdh;
}

import common.containers;
import common.io;
import common.utils;

extern(C) {
    void dumpGPR();
    void dumpXMM_PS();
    void dumpXMM_PD();
}
