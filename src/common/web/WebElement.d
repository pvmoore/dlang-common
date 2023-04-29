module common.web.WebElement;

import common.web;

class WebElement {
public:
    string name;
    WebElement parent;
    WebElement[] children;

    WebAttributes attributes;
    string text;

    bool hasAttribute(string key) { return attributes.containsKey(key); }
    string getAttribute(string key) { return attributes.get(key); }

    this(string name) {
        this.name = name;
        this.attributes = new WebAttributes();
    }
    void add(WebElement e) {
        e.parent = this;
        children ~= e;
    }
    WebElement[] findAll(string name) {
        WebElement[] array;
        if(this.name==name) array ~= this;
        foreach(ch; children) {
            array ~= ch.findAll(name);
        }
        return array;
    }
    WebElement findFirst(string name) {
        if(this.name==name) return this;
        foreach(ch; children) {
            if(auto result = ch.findFirst(name)) return result;
        }
        return null;
    }
    WebElement findFirst(bool delegate(WebElement) func) {
        if(func(this)) return this;
        foreach(ch; children) {
            if(auto result = ch.findFirst(func)) return result;
        }
        return null;
    }
    string dumpToString(string indent = "") {
        string s = "%s%s\n".format(indent, name);
        foreach(ch; children) {
            s ~= ch.dumpToString(indent ~ "  ");
        }
        return s;
    }
    override string toString() {
        return "<%s>".format(name);
    }
private:
}