module _tests.test_web;

import std.stdio : writeln, writefln;
import common.web;

void testWeb() {
    writefln("========--\nTesting web\n==--");

    string src =
    "<!DOCTYPE html> <html lang=\"en-US\"> <head> <meta charset=\"utf-8\">" ~
        "<title>Hello</title>" ~
        "<link rel='stylesheet' href='blah'>" ~
        "<script type=\"text/javascript\">some script</script>" ~
        "</head>" ~
        "<body>" ~
        "" ~
        "</body>" ~
        "</html>";

    WebPageParser parser = new WebPageParser();
    WebPage page = parser.parsePage(src);

    writeln(page.dumpToString());

    

}