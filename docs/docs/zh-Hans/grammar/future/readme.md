# 异步操作（Future）

河图脚本有可能获得一个 Dart 中的 Future 对象。为了方便起见，我们提供了一个简单的封装，让脚本可以和 Future 交互。

你可以在脚本中通过 then() 来传递一个脚本中的函数，它将会在这个 Future 完成后被执行：

```dart
import 'package:hetu_script/hetu_script.dart';

Future<void> fetch() {
  // Imagine that this function is fetching user info from another service or database.
  return Future.delayed(
      const Duration(seconds: 2), () => print('Hello world after 2 seconds!'));
}

void main() {
  final hetu = Hetu();
  hetu.init(externalFunctions: {'fetch': fetch});
  hetu.eval(r'''
      external function fetch
      final future = fetch()
      future.then((value) {
        print('future completed!')
      })
  ''');
}
```

## 手动创建一个 Future 对象

河图 0.4.0 版本之后，可以通过 Future 类的构造函数手动创建一个 Future 对象：

```dart
final a = Future( () => 42 )
a.then( (value) => print(value) )
print(41)
```

上面的代码将会先打印 41，然后打印 42。

你也可以在函数定义代码块的括号之前添加 `async` 关键字来方便的返回一个 Future 对象：

```dart
// 函数声明时附带async
function testAsync async {
  // some code
}

// 匿名函数附带async
() async {
  // some code
} ().then((value) {
  // 匿名函数的好处是可以原地立即执行，这种用法类似 Javascript
})

```

这种方式声明的函数，本质上还是创建了一个 Dart 的 Future 对象。然后将脚本函数作为其参数。

## 等待多个 Future 返回

河图 0.4.0 版本之后，可以使用 Future 类上的静态函数 wait() 来等待多个 Future 完成，然后统一返回。

注意在脚本中，不能使用 Dart 的泛型参数，因此所有的 Future 返回的都是 dynamic 类型。

```dart
async asyncFunc1 => 41
async asyncFunc2 => 42

Future.wait([asyncFunc1(), asyncFunc2()]).then((valueList) {
  print(valueList)
})
```

上述的代码将会打印：

```
[
  41,
  42
]
```

## await

在河图 0.5.0 版本之后，可以在部分情况下支持 await 关键字，来避免过于复杂的 `then` 形式的回调函数。

目前这是一个试验性质的功能，可能会有一些潜在的 bug，而且也并非在所有场景下都支持使用 `await`。

目前仅可以在普通的表达式中使用。包括变量初始化表达式等等。

但不能在 for 循环的初始化表达式，以及函数调用参数中的表达式中使用 `await`。

可以使用 await 的场合的简单例子：

```dart
final result = await fetch() * await valueFuture() * await sumAll();
```
