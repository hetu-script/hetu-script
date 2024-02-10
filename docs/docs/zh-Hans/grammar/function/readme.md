# 函数和方法（function & method）

河图中的函数使用不同的关键字来声明，这代表了函数的类型，例如：**function, get, set, constructor, factory**。

函数声明的每一个部分都可能省略。如果省略了参数列表，则连参数列表的空括号也可以不用写。

```typescript
function doubleIt(n: num) -> num {
  return n * 2
}

function main {
  def x = doubleIt(7) // expect 14
  print(x)
}
```

函数定义的语句块中也可以定义函数和类。

函数在河图中是一等公民，可以将其当做表达式求值，也可以作为参数传递。

```typescript
function closure(func) {
  var i = 42
  function nested {
    i = i + 1
    return(func(i))
  }
  return nested
}

function main {
  var func = closure( (n) => n * n )
  print(func()) // print: 1849
  print(func()) // print: 1936
}
```

## 单行函数

和 Dart 一样，你可以使用 '=>' 来定义以一个表达式作为定义的函数：

```dart
var func = (x) => x * x
final sq = func(4) // sq = 16
```

## 可选参数

和 Dart 一样，你可以使用可选位置参数，或者可选命名参数。并且也可以为其指定默认值。和 Dart 的不同之处在于，对于提供了默认值的参数，只要传递进来的值是 null，都会使用默认值来替换。

```javascript
function posParam(a, [b = 7]) {
  return a * b
}


final r1 = posParam(6) // r1 = 42

function namedParam({a = 3, b = 9}) {
  return a * b
}

final r2 = namedParam(b: 10) // r2 = 30
```

## 变长参数列表

使用 '...' 来定义一个变长参数列表。此时这个函数可以接受任意长度的参数数量。在函数定义中，这个变长参数的名字将会以一个包含全部剩余参数的 List 作为它的值。

```javascript
external function print(... args: any)

print('hello', 'world!', 42) // okay!
```

## 省略参数名

你可以用 '\_' 来省略某个参数的名字。这在某些函数式编程的场合有用，某些函数的实现用不到某些参数。

```javascript
function test1(expect, value, [arg]) {
  print("running test1 with ${arg}: expect ${expect}, value ${value}");
}

function test2(_, value, [_]) {
  print(value);
}

function run(expect, value) {
  test1(expect, value, "test1");
  test2(expect, value, "test2");
}
```

## 函数的返回值

如果函数定义中没有显式提供 return 语句，函数将会返回最后一行语句的求值（可能为 null）。

## 匿名函数（也叫函数表达式，函数字面量或者 lambda）

```javascript
function closure(func) {
  var i = 42;
  function nested() {
    i = i + 1;
    print(func(i));
  }
  return nested;
}

var func = closure((n) => n * n);
func();
```

函数表达式和普通的函数声明的不同之处在于。函数关键字也可以省略，但此时不能省略参数列表的括号。下面五种函数字面量都是合法的：

```dart
final func0 = function meaning { return 42 }
final func1 = function { return 42 }
final func2 = function => 42
final func3 = () { 42 }
final func4 = () => 42
```

## 立即执行的匿名函数

匿名函数本质上是个表达式，因此他可以求值，因此也可以立即对其进行函数执行：

```javascript
() {
  return Future( () => 42 )
} ().then(
  (value){
    print(value)
  }
)
print(41)
```

上面的例子中，在一个匿名函数中创建了一个 Future 对象，然后立即执行这个匿名函数并使用 then() api 绑定了一个回调函数。
最终执行结果是先打印 41，然后再打印 42。

## 匿名函数和 struct 的交互

### bind()

bind 可以获得一个新的匿名函数，并且新函数是这个 struct 的成员函数。函数定义中的 this 将会绑定到这个 struct 上。这在某些需要分离逻辑和数据的场合比较有用。

```dart
final obj = {
  name: 'nobody'
}
final func = () {
  this.name = 'foobar'
}
final newfunc =func.bind(obj)
newfunc()
print(obj.name) // 'foobar'
```

### apply()

apply 和 bind() 类似，但只是一次性的将这个函数绑定到这个 struct 并立即调用，并不会获得新函数，也不会修改原来的函数。

```dart
final obj = {
  name: 'nobody'
}
final greeting = () {
  print('Hi! I\'m ${this.name}')
}
greeting.apply(obj)
```
