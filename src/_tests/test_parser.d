module _tests.test_parser;

import common;
import common.parser;
import common.utils;

import std.stdio;

void testParser() {
    writefln("========--\nTesting ExpressionParser\n==--");

    testSimple();
    testSimpleWithRefs();
    testSimpleWithRefTokens();
    testUnableToResolveRefTokens();
    testUnableToResolve();
    testBadSyntax();
    testWithMutableRefTokens();
}

void testSimple() {
    auto parser = new ExpressionParser!int();
    int a = parser.parse(["(", "10", "+", "10", ")", "*", "2", "/", "2"]);
    assert(a == 20);

    int b = parser.parse(["(", "20", "-", "10", ")", "/", "3"]);
    assert(b==3);

    int c = parser.parse(["(", "20", "-", "10", ")", "%", "3"]);
    assert(c==1);

    int d = parser.parse(["-1"]);
    assert(d==-1);

    int e = parser.parse(["-1", "+", "1"]);
    assert(e == 0);

    int f = parser.parse(["-", "1", "+", "1"]);
    assert(f == 0);

    int g = parser.parse(["255", "&", "15"]);
    assert(g==15);

    int h = parser.parse(["16", "|", "15"]);
    assert(h==31);

    int i = parser.parse(["31", "^", "15"]);
    assert(i==16);
}

void testSimpleWithRefs() {
    auto parser = new ExpressionParser!int();

    parser.addReference("two", 2);
    parser.addReference("three", 3);
    parser.addReference("ten", 10);
    parser.addReference("twenty", 20);

    int a = parser.parse(["(", "ten", "+", "ten", ")", "*", "two", "/", "two"]);
    assert(a == 20);

    int b = parser.parse(["(", "twenty", "-", "ten", ")", "/", "three"]);
    assert(b==3);

    int c = parser.parse(["(", "twenty", "-", "ten", ")", "%", "three"]);
    assert(c==1);

    int d = parser.parse(["-", "two"]);
    assert(d==-2);
}

void testSimpleWithRefTokens() {
    auto parser = new ExpressionParser!int();

    parser.addReference("twenty", ["ten", "*", "two"]);
    parser.addReference("ten", ["two", "*", "5"]);
    parser.addReference("three", ["two", "+", "1"]);
    parser.addReference("two", ["2"]);

    int a = parser.parse(["(", "ten", "+", "ten", ")", "*", "two", "/", "two"]);
    assert(a == 20);

    int b = parser.parse(["(", "twenty", "-", "ten", ")", "/", "three"]);
    assert(b==3);

    int c = parser.parse(["(", "twenty", "-", "ten", ")", "%", "three"]);
    assert(c==1);
}

void testUnableToResolveRefTokens() {
    auto parser = new ExpressionParser!int();
    parser.addReference("four", ["1"]);
    parser.addReference("five", ["six"]);
    parser.addReference("six", ["five"]);
    string msg;
    try{
        parser.parse(["1"]);
    }catch(Exception e) {
        msg = e.msg;
    }
    assert(msg !is null);
    assert(msg.contains("five") && msg.contains("six"));
    assert(!msg.contains("four"));
}

void testUnableToResolve() {
    auto parser = new ExpressionParser!int();
    parser.addReference("one", 1);

    string msg;
    try{
        parser.parse(["1", "+", "(", "two", "-", "(", "one", ")", ")"]);
    }catch(Exception e) {
         msg = e.msg;
    }
    assert(msg.contains("two"));
    assert(!msg.contains("one"));
}

void testBadSyntax() {
    auto parser = new ExpressionParser!int();
    string msg;
    try{
        parser.parse(["1", "+", "("]);
    }catch(Exception e) {
         msg = e.msg;
    }
    assert(msg.contains("Syntax error"));

    msg = null;
    try{
        parser.parse(["1", "+", "+", "2"]);
    }catch(Exception e) {
         msg = e.msg;
    }
    assert(msg.contains("Syntax error"));
}

void testWithMutableRefTokens() {
    auto parser = new ExpressionParser!int();

    parser.addReference("twenty", ["ten", "*", "two"]);
    parser.addReference("ten", ["two", "*", "5"]);
    parser.addReference("three", ["two", "+", "1"]);
    parser.addReference("two", ["$"]);
    parser.addReference("one", ["1", "+", "1"]);

    parser.addMutableReference("$", 3);

    // two    = 3
    // three  = 3 + 1 = 4
    // ten    = 3 * 5 = 15
    // twenty = 15 * 3 = 45
    // one    = 2
    // (ten+ten)*two/two = (15+15)*3/(3+2) = 30
    int a = parser.parse(["(", "ten", "+", "ten", ")", "*", "two", "/", "(", "two", "+", "one", ")"]);
    assert(a == 18);

    parser.addMutableReference("$", 4);

    // two    = 4
    // three  = 4 + 1 = 5
    // ten    = 4 * 5 = 20
    // twenty = 20 * 4 = 80
    // (twenty-ten)/three = (80-20)/5 = 12
    int b = parser.parse(["(", "twenty", "-", "ten", ")", "/", "three"]);
    assert(b==12);

    parser.addMutableReference("$", 5);

    import std.format;

    // two    = 5
    // three  = 5 + 1     = 6
    // ten    = 5 * 5     = 25
    // twenty = 25 * 5    = 125
    // (twenty-ten)/three = (125-25)%6 = 12
    int c = parser.parse(["(", "twenty", "-", "ten", ")", "%", "three"]);

    assert(c==4, "%s".format(c));
}
