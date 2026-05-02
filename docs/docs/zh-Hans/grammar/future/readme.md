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

在河图 0.5.0 版本之后，可以在 async 函数中使用 `await` 关键字，来避免过于复杂的 `then` 形式的回调函数。

`await` 关键字已经完整实现。在 async 函数或脚本中，`await` 会暂停执行直到 Future 完成。解释器会保存和恢复完整的执行上下文（包括指令指针、命名空间和操作数栈），因此 `await` 可以在嵌套函数调用、循环和条件分支中正确工作。

示例：

```dart
async function fetchData {
  final a = await fetch()
  final b = await valueFuture()
  return a + b
}
```

```dart
final result = await fetch() * await valueFuture() * await sumAll();
```

### await 的使用限制

`await` 关键字在所有表达式上下文中都可以使用 — 包括列表字面量、结构体字面量、字符串插值、函数调用参数、switch case 值、算术表达式以及脚本和函数体内的变量初始化表达式。

仅有三处**不支持** `await`：

- **模块 (.ht) 顶层变量初始值** — 模块级变量使用延迟初始化，无法为 `await` 挂起。请改用函数。
- **命名结构体成员初始值**（包括 `static var` 字段和实例字段默认值）— 结构体构造是同步的。
- **函数参数默认值** — 分析器在编译期会拒绝参数默认值中的 `await`。

```dart
// 在模块 (.ht) 中，不要这样写：
// final x = await fetch()

// 改为使用函数：
function init async {
  final x = await fetch()
}
```

### await 的内部实现

当解释器遇到 `await` 表达式时，它会检查操作数栈顶是否是 Dart 的 `Future` 对象。如果是，则将当前执行上下文（指令指针、命名空间、栈帧）保存到 `FutureExecution` 对象中并挂起。当 Future 完成后，解释器从保存的上下文中恢复执行，将解析后的值压入栈中。对于链式 Future，此过程会重复进行，直到没有更多待处理的 Future 为止。
