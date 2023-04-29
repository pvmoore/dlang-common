module common.web.WebAttributes;

import common.web;

final class WebAttributes {
public:
    string[string] map;

    void add(string key, string value) {
        map[key] = value;
    }
    bool containsKey(string key) {
        return (key in map) !is null;
    }
    string get(string key) {
        auto p = key in map;
        if(p) return *p;
        return "";
    }
    override string toString() {
        return "%s".format(map);
    }
private:
}