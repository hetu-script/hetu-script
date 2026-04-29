# Control flow

Hetu has while, do loops, and classic for(init;condition;increment) and for...in loops. As well as `switch` statement.

```dart
function main {
  var i = 0
  for (;;) {
    ++i
    switch (i % 2) {
      0 => print('even:', i)
      1 => print('odd:', i)
      else {
        print('never going to happen.')
      }
    }
    if (i > 5) {
      break
    }
  }
}
```

## If

**if** statement's branches could be a single statement without brackets.

```javascript
if (condition) {
  ...
} else {
  ...
}
```

**if** can also be an expression which will have a value, in this case else branch is not omitable.

## Loop

Syntax for loop statement is the same to most C++/Java like languages.

You can use break and continue within them.

### While

```javascript
while (condition) {
  ...
}
```

### Do

```javascript
do {
  ...
} while (condition)
```

'do' statement's 'while' part is optional, if omitted, it will become a anonymous code block. It's kind of like an anonymous function that immediately calls.

### For

'for' statement's expr must be separated with ';'.

The expression itself is optional. If you write 'for ( ; ; )', it will be the same to 'while (true)'

When use for...in, the loop will iterate through the keys of a list.

When use for...of, the loop will iterate through the values of a struct literal/Dart Map.

```dart
for (init; condition; increment) {
  ...
}

for (var item in list) {
  ...
}

for (var item of obj) {
  ...
}
```

## Switch

`switch` evaluates an optional condition expression and matches it against case branches. If no condition is provided, it behaves like an if-else chain, jumping to the first truthy branch.

There are three case matching modes:

### 1. Equals matching (`case` value)

Matches a single value against the condition. Use comma-separated values to match multiple alternatives in one branch.

```javascript
switch (i) {
  0 => print('zero')
  1, 2, 3 => print('one to three')
}
```

### 2. Either-equals matching (comma expression)

A shorthand for matching multiple distinct values in one case. The case matches if the condition equals any of the listed values.

### 3. Element-in matching (`in` / `of`)

Checks whether the condition value is contained within an iterable or struct/map.

```javascript
switch (i) {
  in [4, 9] => print('square')
  of { key: 'value' } => print('found in struct values')
}
```

### Type value pattern matching (`typeval`)

When the condition is a type value, you can use `typeval` in cases to match against specific type patterns:

```dart
function checkType(t: type) {
  switch (t) {
    typeval {} : print('a structural type')
    typeval ()->any : print('a function type')
    else => print('other type')
  }
}
```

### Case syntax

- `case` keyword is optional for each branch.
- Single-expression branches use `=>` (like arrow functions).
- Block branches use `:`.
- The else/default branch uses `else`, `default`, or `_`.
- The else branch is optional.
- Unlike C/Java, `break` is **implicit** — execution never falls through to the next case.

### Condition-less switch (truthy switch)

When no condition expression is provided, each case's expression is evaluated as a boolean:

```dart
switch {
  x > 0 => print('positive')
  x < 0 => print('negative')
  else => print('zero')
}
```

Note: The interpreter does NOT [implicitly convert non-boolean values](../strict_mode/readme.md#truth-value) in switch conditions.

```javascript
for (final i in range(0, 10)) {
  switch (i) {
    case 0 : {
      print('number: 0')
    }
    2, 3, 5, 7 : {
      print('prime: ${i}')
    }
    in [4, 9] : {
      print('square: ${i}')
    }
    else => print('other: ${i}')
  }
}
```
