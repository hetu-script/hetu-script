# Error & exception

You can manually throw a dart exception within the script using the **assert** or **throw** keyword.

## assert

```dart
assert(1 > 5)
```

Will throw an 'assertion failed' error. And the error message will contain the source code text in the parentheses to let you know why this happened.

The expression within the parentheses must be a boolean value.

## throw

```dart
var i = 42
throw 'i is ${i}!'
```

Will throw an 'script throws' error. And the error message will contain the toString() value of the expression after the keyword.

You have to provided a expression after the throw, although the value of that expression might be null.

## Error handling

The script doesn't support 'try...catch' functionality. It's not recommended to try to handle error within the script.
