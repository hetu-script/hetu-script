# Implementation detail

Hetu's bytecode implementation has some inexplicit rules. Normally they won't affect language users. We listed them here in case you are interested or encountered some bytecode issues.

## String interpolation

The string iterpolation's underlying implementation is kind of like C#'s String.format() or python's str.format(). The compiler will replaces those '${expression}' into '{0}', '{1}' forms.

```python
"{0} {1}".format("hello", "world")
```

The interpreter will replace those with actual values in runtime.

So you should avoid having literal '{0}', '{1}' sub strings in a String interpolation, it might cause unintended effects.

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
  Country._(name) {
    _name = name;
  }
  fun toString = 'Country.${_name}'
  static final kHungary = ENUM._('kHungary')
  static final kJapan = ENUM._('kJapan')
  static final kIndia = ENUM._('kIndia')
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
  if (isReady) return; // a semicolon will always be inserted here automatically by javascript engine
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
