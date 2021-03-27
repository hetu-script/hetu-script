# Hetu script - Control flow

## If

If statement's condition expression must be bool.
If statement's then branch and else branch's curly brackets is optional.

```dart
if (condition) {
  ...
} else {
  ...
}
```

## While

While statement's condition is optional. If the condition is omitted, then it's equal to 'while (true)'.

```dart
while (condition) {
  ...
}
```

## Do

Do statement's condition is NOT optional.

```dart
do {
  ...
} while (condition)
```

## For

For statement's expr must be separated with ';'. The expression itself is optional. If you write 'for (;;)'

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
