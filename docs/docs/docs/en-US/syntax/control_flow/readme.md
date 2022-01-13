# Control flow

Hetu has while, do loops, and classic for(init;condition;increment) and for...in loops. As well as when statement, which works like switch.

```dart
fun main {
  var i = 0
  for (;;) {
    ++i
    when (i % 2) {
      0 -> print('even:', i)
      1 -> print('odd:', i)
      else -> print('never going to happen.')
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

## When

When is the substitue for 'switch' in older programming languages, we change its name to indicate more complex usages.

'when' statement's condition is optional. If not provided, the interpreter will check the cases and jump to the first branch if the expression evaled as true. In this case, the when statement is more like a if else statement except with a little more efficiency because it won't go through every branch.

'when' statement's case could be non-const expression or variables;

'when' statement's body must be enclosed in curly brackets. However, the case branch could be a single statement without brackets;

'when' statement's else branch is optional.

```javascript
when (condition) {
  expr -> expr // ...single expression...
  expr -> {
    // ...block statement...
  }
  // will not fall through here
  else -> {
    // ...
  }
}
```
