module common.utils.static_utils;

import std.traits :
    isArray,
    isPointer,
    isSigned,
    isUnsigned,
    isSomeFunction,
    isFloatingPoint,
    isAssociativeArray;

template isStruct(T) {
	const bool isStruct = is(T==struct);
}
template isObject(T) {
    const bool isObject = is(T==class) || is(T==interface);
}
template isPrimitiveType(T) {
    const bool isPrimitiveType =
        is(T==bool)  ||
        is(T==byte)  || is(T==ubyte) ||
        is(T==short) || is(T==ushort) ||
        is(T==int)   || is(T==uint) ||
        is(T==long)  || is(T==ulong) ||
        is(T==float) || is(T==double) || is(T==real);
}

bool hasMethod(T,string M)() if(isStruct!T || isObject!T) {
    static if(__traits(hasMember, T, M)) {
        return isSomeFunction!(__traits(getMember, T, M));
    } else {
        return false;
    }
}

bool isValidMapKey(T)() {
    static if(isPrimitiveType!T) {
        return true;
    } else static if(isObject!T || isStruct!T) {
        return hasMethod!(T,"toHash") &&
               hasMethod!(T,"opEquals");
    } else {
        return false;
    }
}

string[] getAllProperties(T)() if(isStruct!T || isObject!T)
{
	string[] props;
	foreach(m; __traits(allMembers, T)) {
		static if(!isSomeFunction!(__traits(getMember, T, m)) && m!="Monitor") {
			props ~= m;
		}
	}
	return props;
}

string[] getAllFunctions(T)() if(isStruct!T || isObject!T)
{
	string[] funcs;
	foreach(m; __traits(allMembers, T)) {
		static if(isSomeFunction!(__traits(getMember, T, m)) && m!="factory") {
			funcs ~= m;
		}
	}
	return funcs;
}

string[] getAllSubTypes(T)() if(isObject!T) {
    import std.traits : isFinalClass;
    static if(isFinalClass!T) return null;
    // don't know how to get the sub-types :(
    return null;
}

/*
 *  auto b = toArray!VkImageUsageFlagBits(bits);
 */
E[] toArray(E)(uint bits) if (is(E == enum)) {
    import std.traits : EnumMembers;
    E[] array;
    foreach(e; EnumMembers!E) {
        if(bits & e) array ~= e;
    }
    return array;
}

