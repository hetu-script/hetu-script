# Hetu script - Control flow

## If

If statement's condition expression must be bool.
If statement's then branch and else branch's curly brackets is optional.
If statement's branches could be a single statement without brackets.

```dart
if (condition) {
  ...
} else {
  ...
}
```

## While

While statement's condition is optional. If the condition is omitted, then it's equal to 'while (true)'.
While statement's body could be a single statement without brackets.

```dart
while (condition) {
  ...
}
```

## Do

Do statement's condition is NOT optional.
Do statement's body could be a single statement without brackets.

```dart
do {
  ...
} while (condition)
```

## For

For statement's expr must be separated with ';'. The expression itself is optional. If you write 'for (;;)'
For statement's body must be enclosed in curly brackets.

```dart
for ( init; condition; increment) {
  ...
}
```

For statement has two special usage:

```dart
for (var/let/const varName in/of object) {
  ...
}
```

When use for...in, the loop will iterate through the keys of a list/map, and when use for...of, the loop will iterate through the values of a map.

## When

When statement's condition is optional.
When statement's case could be non-const expression or variables;
When statement's body must be enclosed in curly brackets. However, the case branch cloud be a single statement without brackets;

```dart
When (condition) {
  expr : {

  }
  expr : {

  }
}
```
