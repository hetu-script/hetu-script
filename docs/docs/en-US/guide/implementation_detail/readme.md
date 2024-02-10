# Implementation detail

Hetu's bytecode implementation has some inexplicit rules. Normally they won't affect language users. We listed them here in case you are interested or encountered some bytecode issues.

## Enum

The enum is compiled into class, so there's no 'enum' object exists in runtime.

For example, a enum declaration in Hetu:

```dart
enum Country {
  kHungary,
  kJapan,
  kIndia,
}
```

is compiled into:

```dart
class Country {
  final _name;
  constructor _(name) {
    _name = name;
  }
  function toString => 'Country.${_name}'
  static final kHungary = Country._('kHungary')
  static final kJapan = Country._('kJapan')
  static final kIndia = Country._('kIndia')
  static final values = [kHungary, kJapan, kIndia]
}
```

in bytecode.

However, a external Dart enum will exist as a standalone object in the runtime.

## Automatic semicolon insertion

Automatic semicolon insertion (ASI) is a technique in programming languages that semicolon is optional. [Click here for more information](https://en.wikibooks.org/wiki/JavaScript/Automatic_semicolon_insertion).

If a language has no semicolon and in the same time it also allows for multiline expression. Then there will be times that ambiguity happens.

For example:

```javascript
function getObject() {
  if (isReady) return; // a semicolon will always be inserted here automatically by Javascript engine
  {
    // fields
  }
  // some codes
}
```

If there's no ASI, we would never know if you want to return the object after it, or you just want to start a new line after the return keyword.

Similar things also happens when you started a line with brackets, and the interpreter will not knowing if you want to get the subscript value out of the object in the previous line.

In Hetu script, the ASI is slightly different from Javascript's approach (which almost will always add the semicolon at the end of a line).

We would only add a 'end of statement mark' after a line, if the next line starts with one of these tokens:

'{', '(', '[', '++', '--'

**AND** this line is not an **UNFINISHED** line, which ends with one of these tokens:

'!', '\*', '/', '%', '+', '-', '<', '<=', '>', '>=', '=', '!=', '??', '&&', '||', '=', '+=', '-=', '\*=', '/=', '??=', '.', '(', '{', '[', ',', ':', '->', '=>'.

Besides, Hetu will also add a 'end of statement mark' after return if there's a new line immediately after it.

So if you would like to return the value, remember to make the left bracket same line with the return.

And if you want to write function definition, remember to make the left bracket same line with the function parameters.

## Recursive import

For **ResourceType.hetuModule**, recursive import (i.e. A import from B in the meantime, B import from A) is allowed. However, for **ResourceType.hetuScript**, recursive import would cause stack overflow errors. **You have to manually avoid recursive import in '\*.hts' files.**

## for...in Loop

Loop statement **for...in** in Hetu is basically a syntax sugar using iterator. That is to say, a code like:

```dart
for (var i in range(5)) {
  print(i)
}
```

will be compiled into:

```dart
final __iter0 = range(5).iterator
while (__iter0.moveNext()) {
  var i = __iter0.current
  print(i)
}
```

It's not nessesarily a Dart iterator. It's possible to define a object in Hetu that has a **iterator** as its member, while this iterator object has a **moveNext()** method, for this to work.

## Closure

In Hetu, invoke a function will always create a new namespace. And within a namespace, you can access the declarations within its upper namespace.

This kind of implementation likes Javascript's style, it is different from C++/Rust, which provide lexical closure, that you can use **move** and value arguments to create a independent namespace while also capture outter declarations.
