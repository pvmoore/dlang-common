module common.utils.static_utils;

public import std.traits :
    isArray,
    isPointer,
    isSigned,
    isUnsigned,
    isSomeFunction,
    isSomeString,
    isFloatingPoint,
    isAssociativeArray;

import std.traits :
    InoutOf,
    Parameters,
    ReturnType;

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
template isInteger(T) {
    const bool isInteger =
        is(T==byte)  || is(T==ubyte) ||
        is(T==short) || is(T==ushort) ||
        is(T==int)   || is(T==uint) ||
        is(T==long)  || is(T==ulong) ||

        is(T==const(int));
}
template isEnum(T) {
    const bool isEnum = is(T==enum);
}

/**
 * assert(hasProperty!(A,"foo"));
 */
bool hasProperty(T, string prop)() {
    static if(__traits(hasMember, T, prop)) {
        return !isSomeFunction!(__traits(getMember, T, prop));
    } else {
        return false;
    }
}
/**
 * assert(hasProperty!(A,"foo",int));
 */
bool hasProperty(T, string prop, TYPE)() {
    static if(__traits(hasMember, T, prop)) {
        alias member = __traits(getMember, T, prop);
        static if(!isSomeFunction!(member)) {
            return is(typeof(member)==TYPE);
        } else return false;
    } else {
        return false;
    }
}
/**
 * Returns true if the type has a method with the given name regardless of return type or parameters.
 *
 * assert(hasMethodWithName!(A,"bar"));
 */
bool hasMethodWithName(T,string M)()
    if(isStruct!T || isObject!T)
{
    static if(__traits(hasMember, T, M)) {
        return isSomeFunction!(__traits(getMember, T, M));
    } else {
        return false;
    }
}
/**
 * Returns true only if the type has a method with the given name and the given return type and parameters.
 * Note that the types do not have to explicitly match if they can be converted to the required types.
 *
 * assert(hasMethod!(A,"bar", void, float, bool));
 */
bool hasMethod(T,string NAME, RET_TYPE, PARAMS...)()
    if(isStruct!T || isObject!T)
{
    bool result = false;
    bool temp;
    static if(hasMethodWithName!(T,NAME)) {

        /* Look at all overloads */
        static foreach(func; __traits(getOverloads, T, NAME)) {

            static if(is(ReturnType!func : RET_TYPE)) {
                static if(PARAMS.length == Parameters!func.length) {
                    temp = true;

                    static foreach(i, p; Parameters!func) {
                        static if(!is(p : PARAMS[i])) {
                            temp = false;
                        }
                    }
                    result |= temp;
                }
            }
        }
    }
    return result;
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

/**
 * Returns a list of all functions in the type.
 * 
 * Filters out some magic functions.
 */
string[] getAllFunctions(T)() if(isStruct!T || isObject!T) {
    import common.utils.array_utils;
    static immutable ignore = ["__ctor", "__dtor", "__xdtor", "factory"];
	string[] funcs;
	foreach(m; __traits(allMembers, T)) {
        enum isIgnored = ignore.indexOf(m) != -1;
		static if(isSomeFunction!(__traits(getMember, T, m)) && !isIgnored) {
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
 *  auto b = toString!VkFormatFeatureFlagBits(bits, "VK_FORMAT_FEATURE_", "_BIT");
 */
string toString(E)(uint bits, string removePrefix, string removeSuffix) if (is(E == enum)) {
    import std.traits : EnumMembers;
    import std.string : startsWith, endsWith;
    import std.format : format;
     import core.bitop : popcnt;

    string buf = "[";
    foreach(i, e; EnumMembers!E) {

        if(bits & e) {
            // Skip enum members that have more than one bit set
            if(popcnt(e) > 1) continue;

            string s = "%s".format(e);
            if(removePrefix && s.startsWith(removePrefix)) {
                s = s[removePrefix.length..$];
            }
            if(removeSuffix && s.endsWith(removeSuffix)) {
                s = s[0..$-removeSuffix.length];
            }
            buf ~= (buf.length==1 ? "" : ", ") ~ s;
        }
    }
    return buf ~ "]";
}

/*
 *  auto b = toArray!VkFormatFeatureFlagBits(bits, "VK_FORMAT_FEATURE_", "_BIT");
 */
E[] toArray(E)(uint bits) if (is(E == enum)) {
    import std.traits : EnumMembers;
    import core.bitop : popcnt;

    E[] array;
    foreach(e; EnumMembers!E) {

        // Skip enum members that have more than one bit set
        if(popcnt(e) > 1) continue;

        if(bits & e) {
            array ~= e;
        }
    }
    return array;
}

