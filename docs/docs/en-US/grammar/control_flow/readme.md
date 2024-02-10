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
      else => print('never going to happen.')
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

'switch' statement's condition is optional. If not provided, the interpreter will check the cases and jump to the first branch if the expression evaled as true, just like a if else statement.

However for switch statement's cases, interpreter won't [inexplicitly convert non-boolean values](../strict_mode/readme.md#truth-value).

'switch' statement's case could be non-const expression or variables;

'switch' statement's body must be enclosed in curly brackets. However, the case branch could be a single statement without brackets;

'switch' statement's else branch is optional.

If you want to match multiple values in one branch, use comma expression.

If you want to check if an iterable/object contains the value, use in/of expression.

```javascript
for (final i in range(0, 10)) {
  switch (i) {
    0 => {
      print('number: 0')
    }
    2, 3, 5, 7 => {
      print('prime: ${i}')
    }
    in [4, 9] => {
      print('square: ${i}')
    }
    else => {
      print('other: ${i}')
    }
  }
}
```
