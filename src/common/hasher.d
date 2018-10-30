module common.hasher;

import common.all;

import std.digest;
import std.digest.murmurhash;
import std.digest.sha;

struct Hasher {
    static auto murmur(string data) {
        Hash!16 h;
        h.hash = digest!(MurmurHash3!(128, 64))(data);
        return h;
    }
    static auto sha1(string data) {
        Hash!20 h;
        h.hash = digest!(SHA1)(data);
        return h;
    }
}
struct Hash(int L) {
private:
    ubyte[L] hash;
public:
    string toString() {
        return toHexString!(LetterCase.lower)(hash.dup);
    }
    bool isValid() {
        return !onlyContains(hash.ptr, L, 0);
    }
    void invalidate() {
        hash[] = 0;
    }
}