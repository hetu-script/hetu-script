# Syntax of Hetu Script Language

Hetu's grammar is close to most modern languages, with a few key characteristics:

1, Declarations starts with a keyword before the identifier: var, final, const, fun, construct, get, set, class, type, etc.

2, Semicolon is optional. In most cases, the interpreter will know when a statement is finished. In rare cases, the lexer will implicitly add "end of statement token" (a semicolon in default lexicon) to avoid ambiguities. For example, before a line when the line starts with one of '++, --, (, [, {', or after a line when the line ends with 'return'.

3, Type annotation is optional. Type is annotated **with a colon after the identifier** like typescript/kotlin/swift.

4, Use **when** instead of **switch**
