module common.attributes;

import common.all;

/*
 * Use this to mark a function as asynchronous.
 * eg.
 * @Async void myfunc() {}
 * @Async("Some comment") void myfunc() {}
 */
struct Async {
    string comment;
}

/**
 *  @Implements("TheInterface")
 *
 *  At some point we can probably add a compile-time
 *  check to ensure methods actually implement the
 *  interface they claim to.
 *
 *  auto t = Tuple!(__traits(getAttributes, foo));
 */
struct Implements {
    string interfaceName;
}
/**
 *  @Comment("Thing ...")
 */
struct Comment {
    string value;
}

/**
 * Signifies that we do not own the resource and are not required to destroy it.
 *
 *  @Borrowed MyClass cls;
 */
struct Borrowed {
    string from;
}