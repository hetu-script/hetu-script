# 流程控制

河图中包含大多数常见的流程控制语句。需要注意的是河图用 when 取代了 switch。

```dart
function main {
  var i = 0
  for (;;) {
    ++i
    switch (i % 2) {
      0 => print('even:', i)
      1 => print('odd:', i)
      else {
        print('never going to happen.')
      }
    }
    if (i > 5) {
      break
    }
  }
}
```

## 条件判断语句（if）

```javascript
if (condition) {
  ...
} else {
  ...
}
```

**if** 语句的分支可以是一个表达式，也可以是一个 '{}' 语句块。

**if** 语句本身也可以直接作为一个表达式使用，等同于三目表达式。此时不能忽略 else 分支。

## 循环语句（while, do, for）

这三个语句的用法和大多数 C++/Java 类的语言保持一致。

在这三种循环中，都可以使用 break 和 continue。

### while

```javascript
while (condition) {
  ...
}
```

### do

```javascript
do {
  ...
} while (condition)
```

do 循环的 while 语句可以省略，此时这个语句块类似于一个立即执行的匿名函数。

### for

C++ 的传统三段式 for，以 ';' 分隔，并且每个表达式都可以省略。'for ( ; ; )' 等同于 'while (true)'。

```dart
for (init; condition; increment) {
  ...
}

for...in, 遍历查询某个 Iterable 的成员。

for (var item in list) {
  ...
}

for...of, 遍历查询某个 struct/Map 的 values。

for (var item of obj) {
  ...
}
```

## Switch

`switch` 计算一个可选的 condition 表达式，并将其与各 case 分支进行匹配。如果不提供 condition，行为类似 if-else 链，跳转到第一个真值分支。

有三种匹配模式：

### 1. 等值匹配（`case` 值）

将单个值与 condition 进行匹配。使用逗号分隔的值可以在一行中匹配多个互斥的备选值。

```javascript
switch (i) {
  0 => print('zero')
  1, 2, 3 => print('one to three')
}
```

### 2. 逗号表达式匹配（either-equals）

在一个 case 中匹配多个不同值的简写。如果 condition 等于其中任何一个值，该分支即匹配。

### 3. 元素包含匹配（`in` / `of`）

检查 condition 值是否包含在某个 Iterable 或 struct/Map 中。

```javascript
switch (i) {
  in [4, 9] => print('square')
  of { key: 'value' } => print('found in struct values')
}
```

### 类型值模式匹配（`typeval`）

当 condition 是一个类型值时，可以在 case 中使用 `typeval` 来匹配特定的类型模式：

```dart
function checkType(t: type) {
  switch (t) {
    typeval {} : print('a structural type')
    typeval ()->any : print('a function type')
    else => print('other type')
  }
}
```

### Case 语法

- 每个分支的 `case` 关键字可写可不写。
- 单表达式分支使用 `=>`（类似箭头函数）。
- 代码块分支使用 `:`。
- else/default 分支使用 `else`、`default` 或 `_`。
- else 分支是可选的。
- 与 C/Java 不同，`break` 是**隐式的** — 执行不会贯穿到下一个 case。

### 无条件的 switch（真值 switch）

当不提供 condition 表达式时，每个 case 的表达式被当作布尔值计算：

```dart
switch {
  x > 0 => print('positive')
  x < 0 => print('negative')
  else => print('zero')
}
```

注意：解释器在 switch condition 中不会[隐式转换非布尔值](../strict_mode/readme.md#truth-value)。

```javascript
for (final i in range(0, 10)) {
  switch (i) {
    case 0 : {
      print('number: 0')
    }
    2, 3, 5, 7 : {
      print('prime: ${i}')
    }
    in [4, 9] : {
      print('square: ${i}')
    }
    else => print('other: ${i}')
  }
}
```
