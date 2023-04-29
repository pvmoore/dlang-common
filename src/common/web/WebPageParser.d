module common.web.WebPageParser;

import common.web;
import common.utils : isOneOf;
import std.string   : indexOf, toLower;

final class WebPageParser {
public:
    WebPage parsePage(string src) {
        this.src = src;
        this.pos = 0;
        this.page = new WebPage();
        this.element = page;

        parse();

        return page;
    }
private:
    WebPage page;
    WebElement element;
    string src;
    int pos;

    void parse() {
        string buf;

        while(pos < src.length) {

            char ch = peek();
            //writefln("[%s] ch = %s", pos, ch);

            if(ch < 33) {
                buf ~= ch;
                pos++;
            } else switch(ch) {
                case '<':
                    content(buf);
                    buf = null;

                    if(peek(1)=='!' && peek(2)=='-' && peek(3)=='-') {
                        xmlComment();
                        break;
                    }
                    if(matchesIgnoreCase("<!doctype")) {
                        doctype();
                        break;
                    }
                    if(matches("</")) {
                        endElement();
                        break;
                    }
                    startElement();
                    break;
                default:
                    buf ~= ch;
                    pos++;
                    break;
            }
        }
    }
    char peek(int offset = 0) {
        if(pos+offset >= src.length) return 0;
        return src[pos+offset];
    }
    bool matches(string s, int offset = 0) {
        if(pos+offset+s.length >= src.length) return false;
        return src[pos+offset..pos+offset+s.length] == s;
    }
    /**
     * Assumes 's' is already in lower case
     */
    bool matchesIgnoreCase(string s, int offset = 0) {
        if(pos+offset+s.length >= src.length) return false;

        string other = src[pos+offset..pos+offset+s.length].toLower();
        return other == s;
    }

    void parseWhitespace() {
        while(pos<src.length && peek() < 33) pos++;
    }
    string parseName() {
        // name
        int start = pos;
        while(pos<src.length) {
            auto ch = peek();
            if(ch < 33 || ch=='>' || ch=='=') {
                break;
            }
            pos++;
        }
        return src[start..pos];
    }
    void parseAttributes(WebAttributes a) {
        // k=v k='v' k="v" k >

        while(pos<src.length) {

            parseWhitespace();

            if(peek() == '>') {
                pos++;
                break;
            }

            // name
            string name = parseName();
            parseWhitespace();

            // value
            string value;
            if(peek()=='=') {
                pos++;
                parseWhitespace();

                if(peek()=='\'') {
                    pos++;
                    while(pos<src.length && peek()!='\'') {
                        value ~= src[pos++];
                    }
                    pos++;
                } else if(peek()=='"') {
                    pos++;
                    while(pos<src.length && peek()!='"') {
                        value ~= src[pos++];
                    }
                    pos++;
                } else {
                    while(pos<src.length && peek()!='>' && peek() > 32) {
                        value ~= src[pos++];
                    }
                }
            } else {
                value = "true";
            }

            a.add(name, value);
        }
    }
    void startElement() {
        // <
        int p = pos;
        pos++;
        string name = parseName();

        WebElement e = new WebElement(name);
        parseAttributes(e.attributes);

        element.add(e);

        if(name.isOneOf("meta", "link", "img")) {
            // these don't have any content or an end tag
        } else {
            element = e;
        }
    }
    void endElement() {
        // </
        int p = pos;
        string name = parseName();
        pos++;

        element = element.parent;
    }
    void content(string buf) {
        if(buf.length > 0) {
            element.text ~= buf.idup;
        }
    }
    /**
     * <!DOCTYPE html xxxxx>
     */
    void doctype() {
        while(pos<src.length) {
            auto ch = peek();
            pos++;
            if(ch=='>') {
                break;
            }
        }
    }
    void cStyleComment() {
        assert(false);
    }
    void xmlComment() {
        // <!--
        auto end = src[pos+4..$].indexOf("-->");
        if(end==-1) {
            //writefln("End of comment at %s could not be found", pos);
            pos = cast(int)src.length;
            return;
        }
        pos += 4+end+3;
    }
}