# 异步操作（Future）

河图脚本是完全同步的，也不支持 async/await 语法。

但河图脚本有可能获得一个 Dart 中的 Future 对象。为了方便起见，我们提供了一个简单的封装，让脚本可以和 Future 交互。

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
      external fun fetch
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

上面的代码将会先打印41，然后打印42。

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
