module common.containers.containers_internal;

import common;
import common.containers;
import common.utils;

// https://en.wikipedia.org/wiki/List_of_hash_functions#Non-cryptographic_hash_functions

// hash0 and hash3 seem to be the best ones

ulong hash0(ulong x) {
    x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9L;
    x = (x ^ (x >> 27)) * 0x94d049bb133111ebL;
    x = x ^ (x >> 31);
    return x;
}
ulong hash1(ulong key) {
  key = (~key) + (key << 21); 
  key = key ^ (key >>> 24);
  key = (key + (key << 3)) + (key << 8); 
  key = key ^ (key >>> 14);
  key = (key + (key << 2)) + (key << 4); 
  key = key ^ (key >>> 28);
  key = key + (key << 31);
  return key;
}
ulong hash2(ulong key) {
    key = (~key) + (key << 18); 
    key = key ^ (key >>> 31);
    key = key * 21; 
    key = key ^ (key >>> 11);
    key = key + (key << 6);
    key = key ^ (key >>> 22);
    return key;
}
// This one seems to be the best
ulong hash3(ulong key) {
    return (hash2a((key >>> 32).as!uint).as!ulong << 32) | hash2a(key.as!uint);
}
ulong hash4(ulong key) {
    return (hash3a((key >>> 32).as!uint).as!ulong << 32) | hash3a(key.as!uint);
}
ulong hash5(ulong key) {
    return hash0(key) ^ hash3(key);
}

uint hash2a(uint x) {
    x ^= x >> 16;
    x *= 0x7feb352d;
    x ^= x >> 15;
    x *= 0x846ca68b;
    x ^= x >> 16;
    return x;
}
uint hash3a(uint a) {
   a = (a+0x7ed55d16) + (a<<12);
   a = (a^0xc761c23c) ^ (a>>19);
   a = (a+0x165667b1) + (a<<5);
   a = (a+0xd3a2646c) ^ (a<<9);
   a = (a+0xfd7046c5) + (a<<3);
   a = (a^0xb55a4f09) ^ (a>>16);
   return a;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
ulong djb2_hash(string s) {
    ulong hash = 5381;
    foreach(c; s) {
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
    }
    return hash;
}
