# Hetu script - Control flow

## if

- if statement's condition expression must be bool.
- if statement's then branch and else branch's curly brackets is optional.
- if statement's branches could be a single statement without brackets.

```dart
if (condition) {
  ...
} else {
  ...
}
```

## while

- while statement's condition is optional. If the condition is omitted, then it's equal to 'while (true)'.
- while statement's body could be a single statement without brackets.

```dart
while (condition) {
  ...
}
```

## do

- do statement's condition is NOT optional.
- do statement's body could be a single statement without brackets.

```dart
do {
  ...
} while (condition)
```

## for

- for statement's expr must be separated with ';'.
- The expression itself is optional. If you write 'for (;;)', it will be the same to 'while (true)'
- for statement's body must be enclosed in curly brackets.
- When use for...in, the loop will iterate through the keys of a list.

```dart
for ( init; condition; increment ) {
  ...
}

for (var/let/const varName in list) {
  ...
}
```

## when

- when statement's condition is optional.
- when statement's case could be non-const expression or variables;
- when statement's body must be enclosed in curly brackets. However, the case branch cloud be a single statement without brackets;
- when statement's else branch is optional.

```dart
when (condition) {
  expr : {

  }
  expr : {

  }
  else : {

  }
}
```
