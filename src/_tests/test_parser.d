module _tests.test_parser;

import common;
import common.parser;
import std.stdio;

void testParser() {
    writefln("========--\nTesting ExpressionParser\n==--");

    auto parser = new ExpressionParser!double();

    parser.addReference("three", ["2", "*", "(", "2", "+", "two", ")", "+", "one"]);
    parser.addReference("four", ["3", "*", "three"]);
    parser.addReference("one", 1);
    parser.addReference("two", 2);


    //auto a = parser.parse(["1"]);

    //auto b = parser.parse(["(", "1", ")"]);

    //auto c = parser.parse(["1", "+", "1"]);

    //auto d = parser.parse(["1", "+", "1", "*", "2"]);

    //auto d = parser.parse(["(", "1", "+", "1", ")", "*", "2"]);

    //auto e = parser.parse(["one", "+", "two"]);

    auto f = parser.parse(["1"]);

    testSimple();
    testSimpleWithRefs();
    testSimpleWithRefTokens();
    testUnableToResolveRefTokens();
    testUnableToResolve();
    testBadSyntax();
}

void testSimple() {
    auto parser = new ExpressionParser!int();
    int a = parser.parse(["(", "10", "+", "10", ")", "*", "2", "/", "2"]);
    assert(a == 20);

    int b = parser.parse(["(", "20", "-", "10", ")", "/", "3"]);
    assert(b==3);

    int c = parser.parse(["(", "20", "-", "10", ")", "%", "3"]);
    assert(c==1);
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