module common.bool3;

import common.all;
/**
 *  bool3 b = true
 *  bool3 b = bool3.unknown();
 *
 *  b.setTrue()
 *  b.isTrue()
 *
 */
struct bool3 {
private:
    enum : byte {
        UNKNOWN = -1,
        FALSE   = 0,
        TRUE    = 1
    }
    byte value = UNKNOWN;
nothrow:
pragma(inline,true):
    this(byte v) { value = v; }
public:
    this(bool b) { value = b ? TRUE : FALSE; }
    static bool3 unknown() { return bool3(UNKNOWN); }

    bool isTrue() const { return value == TRUE; }
    bool isFalse() const { return value == FALSE; }
    bool isUnknown() const { return value == UNKNOWN; }
    bool isFalseOrUnknown() const { return value != TRUE; }

    // cast to bool (TRUE==true, FALSE or UNKNOWN==false)
    bool opCast() const { return isTrue(); }

    void setTrue() { value = TRUE; }
    void setFalse() { value = FALSE; }
    void setUnknown() { value = UNKNOWN; }
}

