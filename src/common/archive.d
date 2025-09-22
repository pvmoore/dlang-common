module common.archive;

import common.all;
import std.zip;
///
/// Wrapper for a compressed archive.
/// Currently uses the built-in ZipArchive.
///
final class Archive {
private:
    string filename;
    ZipArchive archive;
    ArchiveMember[string] members;
public:
    struct Member {
        string name;
        ubyte[] data;
        string comment;
    }

    this(string filename) {
        this.filename = filename;
        open();
    }
    void close() {
        write();
    }
    /** Add data to the archive using deflate compression */
    auto add(string name, ubyte[] data, string comment = null) {

        auto member              = new ArchiveMember();
        member.name              = name;
        member.expandedData      = data;
        member.comment           = comment;
        member.compressionMethod = CompressionMethod.deflate;
        archive.addMember(member);

        members[name] = member;

        return this;
    }
    /** Add data to the archive using deflate compression */
    auto add(string name, void* data, ulong numBytes, string comment = null) {
        return add(name, (cast(ubyte*)data)[0..numBytes], comment);
    }
    /** Store raw data without compression */
    auto store(T)(string name, T[] data, string comment) {

        ubyte[] bytes = data.ptr.as!(ubyte*)[0..data.length*T.sizeof];

        auto member              = new ArchiveMember();
        member.name              = name;
        member.expandedData      = bytes;
        member.comment           = comment;
        member.compressionMethod = CompressionMethod.none;
        archive.addMember(member);

        members[name] = member;

        return this;
    }
    auto remove(string name) {
        auto ptr = name in members;
        if(ptr) {
            auto a = *ptr;
            members.remove(name);
            archive.deleteMember(a);
        }
        return this;
    }
    bool contains(string name) {
        return (name in members) !is null;
    }
    Member get(string name) {
        auto ptr = name in members;
        if(ptr) {
            auto a = *ptr;
            if(a.expandedData() is null) {
                archive.expand(a);
            }
            return Member(a.name, a.expandedData(), a.comment);
        }
        return Member(null, null, null);
    }
    T[] getData(T)(string name) {
        auto m = get(name);
        if(m.name is null) return cast(T[])null;

        auto len = m.data.length / T.sizeof;
        return (cast(T*)m.data.ptr)[0..len];
    }
    string getComment(string name) {
        auto m = get(name);
        if(m.name is null) return null;
        return m.comment;
    }
private:
    void open() {
        if(From!"std.file".exists(filename)) {
            this.archive = new ZipArchive(cast(ubyte[])From!"std.file".read(filename));

            foreach(m; archive.directory()) {
                members[m.name] = m;
            }
        } else {
            this.archive = new ZipArchive();
        }
    }
    void write() {
        From!"std.file".write(filename, archive.build());
    }
}
