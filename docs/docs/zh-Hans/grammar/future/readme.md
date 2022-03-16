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
