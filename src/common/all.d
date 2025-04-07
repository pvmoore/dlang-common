module common.all;

public:

import common;
import common.containers;
import common.io;

import core.stdc.string : memmove;
import core.atomic      : atomicOp, atomicLoad, atomicStore, cas, MemoryOrder;
import core.sync.mutex  : Mutex;
import core.sync.semaphore : Semaphore;
import core.thread : Thread;
import core.time : dur;

import std.math                 : abs;
import std.stdio                : writef, writefln;
import std.array                : Appender, appender, join, uninitializedArray;
import std.datetime.stopwatch   : StopWatch;

import std.format   : format;
import std.range    : array;

import std.algorithm.searching : any, all, count;
import std.algorithm.iteration : each, filter, map, sum;
import std.algorithm.sorting   : sort;

import std.traits   : isPointer;

import std.typecons : Tuple, tuple;
