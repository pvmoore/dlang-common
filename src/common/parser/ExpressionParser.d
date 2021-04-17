module common.parser.ExpressionParser;

import common.all;
import common.parser;
import std.conv : to;

/**
 * eg.  auto p = new ExpressionParser!int();
 *      p.addReference("two", 2);
 *      assert(0 == p.parse(["1", "+", "(", "1", "-", "two", ")"]));
 */
final class ExpressionParser(T) {
    auto addReference(string name, string[] tokens) {
        auto node = parseTokens(tokens);
        if(node.isResolved()) {
            addReference(name, node.eval());
        } else {
            this.referenceTokens[name] = node;
        }
        return this;
    }
    auto addReference(string name, T value) {
        references[name] = value;
        return this;
    }
    auto addReferences(T[string] refs) {
        foreach(k,v; refs) {
            addReference(k, v);
        }
        return this;
    }
    T parse(string[] tokens) {

        resolveReferenceTokens();

        auto node = parseTokens(tokens);

        node.resolve(references);

        if(!node.isResolved()) {
            throw new Exception("Unable to resolve tokens %s".format(getUnresolvedTokens(node)));
        }

        return node.eval();
    }
private:
    EPNode!(T)[string] referenceTokens;
    T[string] references;
    int pos;
    string[] tokens;

    string[] getUnresolvedTokens(EPNode!T node) {
        string[] unresolved;
        if(node.isA!(RefNode!T)) {
            auto rn = node.as!(RefNode!T);
            if(!rn.isResolved()) {
                unresolved ~= rn.refName;
            }
        } else {
            foreach(c; node.children) {
                unresolved ~= getUnresolvedTokens(c);
            }
        }
        return unresolved;
    }

    string peek(int offset = 0) {
        if(pos+offset>=tokens.length) return null;
        return tokens[pos+offset];
    }
    bool isNumber(string s) {
        if(s[0]=='-') {
            return isNumber(s[1..$]);
        }
        return s[0] >= '0' && s[0] <='9';
    }
    EPNode!T parseTokens(string[] tokens) {
        this.tokens = tokens;
        this.pos = 0;
        auto parent = new ParensNode!T();
        parse(parent);
        return parent;
    }
    /**
     *  Resolve all reference tokens into references.
     *  @throw Exception if there is an error or any reference could not be resolved
     */
    void resolveReferenceTokens() {
        while(referenceTokens.length > 0) {
            string[] resolvedRefs;

            foreach(k,node; referenceTokens) {

                node.resolve(references);

                if(node.isResolved()) {
                    auto value = node.eval();
                    references[k] = value;
                    resolvedRefs ~= k;
                }
            }

            if(resolvedRefs.length==0) {
                throw new Exception("Unable to resolve tokens %s".format(referenceTokens.keys()));
            }

            foreach(k; resolvedRefs) {
                referenceTokens.remove(k);
            }
        }
    }

    void parse(EPNode!T parent) {
        auto expr = lhs(parent);
        parent.add(expr);
        rhs(parent);
    }

    EPNode!T lhs(EPNode!T parent) {
        if(peek() is null) throw new Exception("Syntax error @ token %s".format(pos));
        if(isNumber(peek())) {
            auto value = to!T(peek());
            pos++;
            return new NumberNode!T(value);
        } else if(peek()=="(") {
            pos++;
            auto parens = new ParensNode!T();
            parse(parens);
            pos++;
            return parens;
        } else {
            auto key = peek(); pos++;
            auto p = key in references;
            if(p) {
                return new NumberNode!T(references[key]);
            }
            return new RefNode!T(key);
        }
    }
    void rhs(EPNode!T parent) {
        while(true) {
            if(peek() is null) return;
            switch(peek()) {
                case ")":
                    return;
                case "+": pos++; parent = attach(parent, new BinaryNode!T(Operator.ADD)); break;
                case "-": pos++; parent = attach(parent, new BinaryNode!T(Operator.SUB)); break;
                case "*": pos++; parent = attach(parent, new BinaryNode!T(Operator.MUL)); break;
                case "/": pos++; parent = attach(parent, new BinaryNode!T(Operator.DIV)); break;
                case "%": pos++; parent = attach(parent, new BinaryNode!T(Operator.MOD)); break;
                default:
                    throw new Exception("Syntax error @ token %s".format(pos));
            }
        }
    }
    EPNode!T attach(EPNode!T parent, EPNode!T newNode) {
        EPNode!T prev = parent;
        while(prev.parent && newNode.precedence() >= prev.precedence()) {
            prev = prev.parent;
        }
        newNode.add(prev.last());

        newNode.add(lhs(newNode));

        prev.add(newNode);

        return newNode;
    }
}