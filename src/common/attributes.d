module common.attributes;

import common.all;

/*
 * Use this to mark a function as asynchronous.
 * eg.
 * @Async void myfunc() {}
 * @Async("Some comment") void myfunc() {}
 */
final struct Async {
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
final struct Implements {
    string interfaceName;
}
/**
 *  @Comment("Thing ...")
 */
final struct Comment {
    string value;
}