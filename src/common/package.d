module common;

version(Win64) {} else { pragma(msg,"Windows 64 bit required"); static assert(false); }

public:

import common.allocator;
import common.archive;
import common.boxing;
import common.array;
import common.attributes;
import common.bool3;
import common.pdh;
import common.list;
import common.hasher;
import common.intrinsics;
import common.objectcache;
import common.pinned_array;
import common.queue;
import common.set;
import common.stack;
import common.stringbuffer;
import common.structcache;
import common.tree_list;
import common.velocity;

import common.async.async_array;
import common.async.async_queue;

import common.containers;

import common.io.byte_reader;
import common.io.byte_writer;
import common.io.bit_reader;
import common.io.bit_writer;
import common.io.console;

import common.utils.array_utils;
import common.utils.async_utils;
import common.utils.map_utils;
import common.utils.static_utils;
import common.utils.string_utils;
import common.utils.timing;
import common.utils.utilities;
