module common;

version(X86_64) {} else { pragma(msg,"64 bit required"); static assert(false); }
version(D_InlineAsm_X86_64) {} else { pragma(msg,"Inline assembler required"); static assert(false); }

public:

import common.allocator;
import common.archive;
import common.boxing;
import common.attributes;
import common.bool3;
import common.hasher;
import common.intrinsics;
import common.objectcache;
import common.pinned_array;
import common.stringbuffer;
import common.structcache;
import common.velocity;

version(Win64) {
    import common.pdh;
}

import common.containers.async_array;
import common.containers.async_queue;

import common.containers;

import common.io.byte_reader;
import common.io.byte_writer;
import common.io.bit_reader;
import common.io.bit_writer;
import common.io.console;

import common.utils.array_utils;
import common.utils.asm_utils;
import common.utils.async_utils;
import common.utils.cpu_utils;
import common.utils.map_utils;
import common.utils.static_utils;
import common.utils.string_utils;
import common.utils.timing;
import common.utils.utilities;

extern(C) {
    void dumpGPR();
    void dumpXMM_PS();
    void dumpXMM_PD();
}
