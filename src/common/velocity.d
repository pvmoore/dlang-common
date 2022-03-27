module common.velocity;
/**
 *  A templating engine similar to Apache velocity.
 *
 *  $KEY -- will be replaced by value
 *  $IF $COND ... $END
 *  $LOOP $ITEMS ... $END
 *
 */
import common.all;

final class Velocity {
private:
	Block root;
    Values values;

	this() {
	    this.root   = new Block(VType.ROOT);
	    this.values = new Values;
	}
public:
	static Velocity fromString(string t) {
	    auto v = new Velocity;
        v.parse(t);
	    return v;
	}
	static Velocity fromFile(string filename) {
	    import std.file;
	    return Velocity.fromString(readText(filename));
	}
	void set(string key, string value) {
        values.strings[key] = value;
	}
	void set(string key, string[string][] value) {
        values.arrays[key] = value;
	}
	string process() {
	    auto buf = new StringBuffer;
	    auto pr  = new BlockProcessor;
	    pr.process(values, buf, root);
	    return buf.toString;
	}
private:
    void parse(string templt) {
        int pos;
        auto parser = new BlockParser;
        parser.parse(templt, pos, root);
    }
}
//===============================================================
private:

enum VType { ROOT, TEXT, KEY, IF, LOOP }

final class Values {
    string[string] strings;
    string[string][][string] arrays;
}

final class Block {
    VType type;
    string content;
    string var;
    Block[] blocks;

    this(VType type) {
        this.type = type;
    }
    auto withContent(string c) {
        this.content = c;
        return this;
    }
    auto withVar(string v) {
        this.var = v;
        return this;
    }
    void writeTo(StringBuffer buf, string indent="") {
        buf ~= "\n" ~ indent ~ "[%s %s %s]".format(type, content, var);
        foreach(b; blocks) {
            b.writeTo(buf,indent ~ "  ");
        }
    }
}
//===========================================================
final class BlockParser {
private:
    auto chars = appender!(char[]);
    string text;
public:
    void parse(string templt, ref int pos, Block parent) {
        while(pos<templt.length) {
            bool found  = readText(templt, pos);

            if(text.length>0) {
                parent.blocks ~= new Block(VType.TEXT).withContent(text);
            }

            if(found) {
                auto key = readKeyword(templt, pos);
                if("END"==key) {
                    return;
                } else if("IF"==key) {
                    readText(templt, pos);
                    key = readKeyword(templt, pos);
                    auto block = new Block(VType.IF).withContent(key);
                    parent.blocks ~= block;
                    parse(templt, pos, block);
                } else if("LOOP"==key) {
                    readText(templt, pos);
                    key = readKeyword(templt, pos);
                    readText(templt, pos);
                    string var = readKeyword(templt, pos);
                    auto block = new Block(VType.LOOP)
                        .withContent(key)
                        .withVar(var);
                    parent.blocks ~= block;
                    parse(templt, pos, block);
                } else {
                    parent.blocks ~= new Block(VType.KEY).withContent(key);
                }
            }
        }
    }
private:
    bool readText(string templt, ref int pos) {
        scope(exit) {
            text = cast(string)chars.data.dup;
            chars.clear();
        }
        for(; pos<templt.length; pos++) {
            char c = templt[pos];
            if(c=='$') {
                if(pos<templt.length-1 && templt[pos+1]=='$') {
                    // $$ is a literal dollar char
                    chars ~= '$';
                    pos++;
                    continue;
                }
                return true;
            }
            chars ~= c;
        }
        return false;
    }
    string readKeyword(string templt, ref int pos) {
        throwIf(templt[pos]!='$');
        pos++;
        int p = pos;
        wlp: while(pos<templt.length) {
            char c = templt[pos];
            switch(c) {
                case '0': .. case '9':
                case 'a': .. case 'z':
                case 'A': .. case 'Z':
                case '.':
                case '_':
                    break;
                default :
                    break wlp;
            }
            pos++;
        }
        return templt[p..pos];
    }
}
//===========================================================
final class BlockProcessor {
    void process(Values values, StringBuffer buf, Block block) {

        void recurse() {
            foreach(b; block.blocks) {
                process(values, buf, b);
            }
        }

        final switch(block.type) with(VType) {
            case TEXT:
                buf ~= block.content;
                break;
            case KEY:
                buf ~= values.strings.get(block.content, "");
                break;
            case IF:
                string obj = values.strings.get(block.content, null);
                bool result = obj !is null && "true"==obj;
                if(result) {
                    recurse();
                }
                break;
            case LOOP:
                string[string][] array = values.arrays.get(block.content, null);
                // array of string maps
                foreach(map; array) {
                    // set keys for this iteration
                    foreach(k,v; map) {
                        values.strings[block.var~"."~k] = v;
                    }
                    recurse();
                }
                break;
            case ROOT:
                recurse();
                break;
        }
    }
}

