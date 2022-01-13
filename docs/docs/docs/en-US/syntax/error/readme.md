# Error hanlding & assert

The script doesn't support 'try...catch' functionality. It's not recommended to try to handle error in the script. You should do this in the Dart code.

You can manually throw a dart exception within the script using the **assert** keyword.

For example, a statement like:

```dart
assert(1 > 5)
```

Will throw an 'assertion failed' error. And the error message will contain the source code text in the parentheses to let you know why this happened.

The expression within the parentheses must be a boolean value.
