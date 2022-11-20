module common.utils.string_utils;

import std.string   : indexOf;
import std.traits   : isSomeChar, isSomeString;
import std.format   : format;
import std.array    : Appender, appender, join;
import std.typecons : Tuple, tuple;

string repeat(string s, long count) {
    if(count<=0) return "";
    auto app = appender!(string[]);
    for(auto i=0; i<count; i++) {
        app ~= s;
    }
    return app.data.join();
}

bool contains(string s, char value) {
    return s.indexOf(value)!=-1;
}
bool contains(string s, string value) {
    return s.indexOf(value)!=-1;
}
bool containsAny(string s, string[] values...) {
    foreach(v; values) {
        if(s.contains(v)) return true;
    }
    return false;
}

bool startsWith(T)(T s, T prefix) if(isSomeString!T) {
	if(!s || !prefix || s.length < prefix.length || prefix.length==0) return false;
	return s[0..prefix.length] == prefix;
	//for(int i; i<prefix.length; i++) {
	//	if(s[i] != prefix[i]) return false;
	//}
	//return true;
}
bool endsWith(T)(T s, T postfix) if(isSomeString!T) {
	if(!s || !postfix || s.length < postfix.length || postfix.length==0) return false;
	for(auto i=s.length-postfix.length, n=0; i<s.length; i++, n++) {
		if(s[i] != postfix[n]) return false;
	}
	return true;
}

// array.removeChars('a')
inout(T)[] removeChars(T)(inout(T)[] s, T ch) if(isSomeChar!T) {
    if(s.length==0 /*|| s.indexOf(ch)==-1*/) return s;

    T[] tmp  = new T[s.length];
    auto pos = 0;

    foreach(c; s) {
        if(c!=ch) {
            tmp[pos++] = c;
        }
    }
    return tmp[0..pos];
}

string toString(float f, int dp) {
    const fmt = "%%.%sf".format(dp);
    return fmt.format(f);
}
int toInt(string s) {
    import std.conv : to;
    return s.to!int;
}

wstring fromWStringz(wchar* chars, int limit=1000) {
	if(chars is null) return ""w;
	int len;
	for(len=0; len<limit; len++) {
		if(chars[len]==0) break;
	}
	auto w = new wchar[len];
	w[0..len] = chars[0..len];
	return cast(wstring)w;
}
size_t toHash(string s) nothrow @trusted {
    return typeid(s).getHash(&s);
}

string getPrefix(string s, string delimiter) {
    if(s is null || delimiter is null) return "";
    auto i = s.indexOf(delimiter);
    if(i!=-1) {
        return s[0..i];
    }
    return "";
}
string getSuffix(string s, string delimiter) {
    if(s is null || delimiter is null) return "";
    auto i = s.indexOf(delimiter);
    if(i!=-1) {
        return s[i+delimiter.length..$];
    }
    return "";
}
Tuple!(string,string) getPrefixAndSuffix(string s, string delimiter) {
    if(s is null || delimiter is null) return tuple("", "");
    auto i = s.indexOf(delimiter);
    if(i!=-1) {
        return tuple(s[0..i], s[i+delimiter.length..$]);
    }
    return tuple("", "");
}
