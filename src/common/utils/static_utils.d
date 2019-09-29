module common.utils.static_utils;

import std.traits :
    isArray,
    isPointer,
    isSigned,
    isUnsigned,
    isSomeFunction,
    isFloatingPoint,
    isAssociativeArray,
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

