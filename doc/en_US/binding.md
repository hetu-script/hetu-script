# Binding

## Function

### Typedef of external function

External functions (for both global and methods) can be binded as the following type:

```dart
typedef HTExternalFunction = dynamic Function(
    {List<dynamic> positionalArgs, Map<String, dynamic> namedArgs, List<HTTypeId> typeArgs});

await hetu.init(externalFunctions: {
  // you can omit the type, and keep the correct type parameter names,
  // this way Dart will still count it as HTExternalFunction
  'hello': ({positionalArgs, namedArgs, typeArgs}) => {'greeting': 'hello'},
});
```

or even you can directy write it as a Dart Function:

```dart
await hetu.init(externalFunctions: {
  'hello': () => {'greeting': 'hello'},
});
```

It's easier to write and read in Dart Function form. However, this way the Interpreter will have to use Dart's [Function.apply] feature to call it. This is normally slower and inefficient than direct call.

## Binding external function

To call Dart functions in Hetu, just init Hetu with [externalFunctions].

Then define those dart funtion in Hetu with [external] keyword.

Then you can call those functions in Hetu.

You can pass object from Dart to Hetu by the return value of external functions.

You can pass object from Hetu to Dart by the return value of Interpreter's [invoke] function;

```typescript
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init(externalFunctions: {
    'hello': (
        {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const []}) => {'greeting': 'hello'},
  });
  await hetu.eval(r'''
      external fun hello
      fun main {
        var dartValue = hello()
        print('dart value:', dartValue)
        dartValue['foo'] = 'bar'
        return dartValue
      }''');

  var hetuValue = hetu.invoke('main');

  print('hetu value: $hetuValue');
}
```

And the output should be:

```
dart value: {greeting: hello}
hetu value: {greeting: hello, foo: bar}
```

## Typedef for unwrap Hetu function into Dart function

In Hetu script:

```dart
fun [DartFunction] add(a: num, b: num): num {
  return a + b
}

fun getFunc {
  return add
}
```

Then when you evaluate this [add] function in Hetu, you will get a native Dart function.

```dart
typedef DartFunction = int Function(int a, int b);

int hetuAdd(DartFunction func) {
  var func = hetu.invoke('getFunc');
  return func(6, 7);
}
```

You have to bind the Dart typedef in [Interpreter.init] before you can use it.

```dart
await hetu.init(externalFunctions: {
  externalFunctionTypedef: {
  'DartFunction': (HTFunction function) {
    return (int a, int b) {
      // must convert the return type here to let dart know its return value type.
      return function.call([a, b]) as int;
    };
  },
});
```

The typedef of the unwrapper is:

```dart
typedef HTExternalFunctionTypedef = Function Function(HTFunction hetuFunction);
```

## Auto-Binding tools

Thanks to [rockingdice](https://github.com/rockingdice) we now have an automated tool for auto-generate both Dart-side and Hetu-side binding declarations for any Dart classes.

Please check out this repository: [hetu-script-autobinding](https://github.com/hetu-script/hetu-script-autobinding)
