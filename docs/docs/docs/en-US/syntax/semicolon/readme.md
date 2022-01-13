# Automatic semicolon insertion

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
