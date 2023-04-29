module common.io.types;

import common.io;
import common.utils;

import std.array    : replace;
import std.string   : lastIndexOf, startsWith;
import std.file     : getSize, exists, mkdirRecurse;
import std.path     : baseName, buildNormalizedPath, dirName, isAbsolute, stripExtension;
import std.format   : format;

struct Filename {
    bool hasExtension;
    string value;

    this(string value) {
        this.value = baseName(value);
        this.hasExtension = this.value.lastIndexOf('.')!=-1;
    }
    //------------------------------------------------------
    bool opEquals(const Filename other) const {
        return this.value == other.value;
    }
    bool opEquals(const string other) const {
        return this.value == other;
    }
    size_t toHash() const @safe nothrow {
        return value.toHash();
    }
    //------------------------------------------------------
    string getBaseName() const {
        if(!hasExtension) return value;
        auto dot = value.lastIndexOf('.');
        return value[0..dot];
    }
    string getExtension() const {
        if(!hasExtension) return null;
        auto dot = value.lastIndexOf('.');
        return dot==-1 ? null : value[dot+1..$];
    }
    auto add(string suffix) const {
        if(hasExtension) {
            return Filename("%s%s.%s".format(getBaseName(), suffix, getExtension()));
        }
        return Filename(value ~ suffix);
    }
    auto withoutExtension() const {
        if(!hasExtension) return this;
        return Filename(stripExtension(this.value));
    }
    auto withExtension(string ext) const {
        ext = ext[0]=='.' ? ext : "." ~ ext;
        if(!hasExtension) return Filename(this.value ~ ext);
        return Filename(stripExtension(this.value) ~ ext);
    }
    string toString() const {
        return value;
    }
}

struct Directory {
    string value;

    this(string value) {
        this.value = buildNormalizedPath(value).replace('\\', '/');
        if(!this.value.endsWith("/")) {
            this.value ~= "/";
        }
        if(isRelative() && this.value.startsWith('/')) {
            this.value = this.value[1..$];
        }
    }
    //------------------------------------------------------
    bool opEquals(const Directory other) const {
        return this.value == other.value;
    }
    bool opEquals(const string other) const {
        return this.value == other;
    }
    size_t toHash() const @safe nothrow {
        return value.toHash();
    }
    //------------------------------------------------------
    void create() {
        mkdirRecurse(value);
    }
    bool exists() const {
        return .exists(value);
    }
    Directory add(Directory dir) {
        return Directory(buildNormalizedPath(value, dir.value));
    }
    Filepath add(Filename name) {
        return Filepath(this, name);
    }
    Filepath add(Filepath path) {
        throwIf(!path.directory.isRelative(), "Cannot add absolute path to directory");
        return Filepath(add(path.directory), path.filename);
    }
    bool isAbsolute() {
        return .isAbsolute(value);
    }
    bool isRelative() {
        return !isAbsolute();
    }
    string toString() const {
        return value;
    }
}

/**
 *  File name with directory
 */
struct Filepath {
    Filename filename;
    Directory directory;

    string value() @safe nothrow const { return directory.value ~ filename.value; }

    this(Directory dir, Filename name) {
        this.directory = dir;
        this.filename = name;
    }
    this(string value) {
        this.filename = Filename(value);
        this.directory = Directory(value[0..value.length-filename.value.length]);
    }
    //------------------------------------------------------
    bool exists() const {
        return .exists(value);
    }
    bool isAbsolute() {
        return directory.isAbsolute();
    }
    bool isRelative() {
        return !isAbsolute();
    }
    ulong size() {
        return getSize(value);
    }
    ubyte[] read() {
        import std.stdio : File;
        File file = File(value, "rb");
        ubyte[] buf = new ubyte[size()];
        file.rawRead(buf);
        return buf;
    }
    string readString() {
        return cast(string)read();
    }
    void write(string s) {
        import std.stdio : File;
        File file = File(value, "wb");
        file.rawWrite(s);
    }
    //------------------------------------------------------
    bool opEquals(const Filepath other) const {
        return this.value() == other.value();
    }
    bool opEquals(const string other) const {
        return this.value() == other;
    }
    size_t toHash() const @safe nothrow {
        return this.value().toHash();
    }
    string toString() const {
        return value();
    }
    //------------------------------------------------------
}