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
    this() {
        this.mutableReferences = new Set!string;
    }
    auto addReference(string name, string[] tokens) {
        this.referenceTokens[name] = tokens;
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
    /**
     * Add a reference that can change value so any other reference that
     * uses this must also be assumed to be non-constant.
     */
    auto addMutableReference(string name, T value) {
        references[name] = value;
        mutableReferences.add(name);
        return this;
    }
    T parse(string[] tokens) {

        resetMutableReferences();
        convertReferenceTokens();
        resolveMutableReferenceNodes();
        resolveReferenceNodes();

        auto node = parseTokens(tokens);

        node.resolve(references);

        if(!node.isResolved()) {
            throw new Exception("Unable to resolve tokens %s".format(getUnresolvedTokens(node)));
        }

        return node.eval();
    }
    T getReference(string key) {
        return references[key];
    }
    T[string] getAllReferences() {
        return references.dup;
    }
private:
    string[][string] referenceTokens;
    EPNode!(T)[string] referenceNodes;
    EPNode!(T)[string] mutableReferenceNodes;
    T[string] references;
    Set!string tempMutableReferences;
    Set!string mutableReferences;
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
            return s.length > 1 && isNumber(s[1..$]);
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
     * Convert all referenceTokens into referenceNodes
     */
    void convertReferenceTokens() {
        foreach(k,tokens; referenceTokens) {
            referenceNodes[k] = parseTokens(tokens);
        }
        referenceTokens.clear();
    }
    /**
     *  Resolve all reference tokens into references.
     *  @throw Exception if there is an error or any reference could not be resolved
     */
    void resolveReferenceNodes() {

        while(referenceNodes.length > 0) {
            string[] resolvedRefs;

            foreach(k,node; referenceNodes) {

                node.resolve(references);

                if(node.isResolved()) {

                    auto value = node.eval();
                    references[k] = value;
                    resolvedRefs ~= k;

                    if(node.containsMutableRef(tempMutableReferences)) {
                        mutableReferenceNodes[k] = node;
                        tempMutableReferences.add(k);
                    }
                }
            }

            if(resolvedRefs.length==0) {
                throw new Exception("Unable to resolve tokens %s".format(referenceNodes.keys()));
            }

            foreach(k; resolvedRefs) {
                referenceNodes.remove(k);
            }
        }

        // At this point we have nothing in the referenceNodes hash
        // but we may have entries in the mutableReferenceNodes for the next
        // time that 'parse' is called.
    }
    /**
     * Resolve these to references temporarily. The references will be removed again
     * after 'parse' so that next time they can be re-generated using possibly
     * different mutable values.
     */
    void resolveMutableReferenceNodes() {

        EPNode!(T)[string] tempRefNodes = mutableReferenceNodes.dup;

        while(tempRefNodes.length > 0) {
            string[] resolvedRefs;

            foreach(k,node; tempRefNodes) {

                node.resolve(references);

                if(node.isResolved()) {
                    auto value = node.eval();
                    references[k] = value;
                    resolvedRefs ~= k;
                }
            }

            if(resolvedRefs.length==0) {
                throw new Exception("Unable to resolve tokens %s".format(tempRefNodes.keys()));
            }

            foreach(k; resolvedRefs) {
                tempRefNodes.remove(k);
            }
        }
    }
    /**
     * Remove all temporary mutable references from the previous 'parse'
     */
    void resetMutableReferences() {

        if(tempMutableReferences) {
            foreach(k; tempMutableReferences.values()) {
                if(!mutableReferences.contains(k)) {
                    references.remove(k);
                }
            }
        }

        tempMutableReferences = new Set!string().add(mutableReferences);
    }

    void parse(EPNode!T parent) {
        auto expr = lhs(parent);
        parent.add(expr);
        rhs(parent);
    }

    EPNode!T lhs(EPNode!T parent) {
        if(peek() is null) throw new Exception("Syntax error @ token %s".format(pos));
        if(peek()=="-") {
            pos++;
            auto neg = new UnaryNode!T(Operator.NEG);
            neg.add(lhs(neg));
            return neg;
        } else if(isNumber(peek())) {
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
                case "&": pos++; parent = attach(parent, new BinaryNode!T(Operator.BITAND)); break;
                case "^": pos++; parent = attach(parent, new BinaryNode!T(Operator.BITXOR)); break;
                case "|": pos++; parent = attach(parent, new BinaryNode!T(Operator.BITOR)); break;
                default:
                    throw new Exception("Syntax error @ token %s '%s' tree=\n%s\ntokens=%s"
                        .format(pos, peek(), parent.dump(), tokens));
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