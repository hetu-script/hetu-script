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
      else => print('never going to happen.')
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

switch 关键字之后，可以跟随一个可选的圆括号内的 condition 表达式。

如果提供了这个表达式，则会将这个表达式的值和各个分支的值进行匹配。并且跳转到第一个匹配的分支。

每个分支的语句，可以只是一个单独的表达式，也可以是一个 '{}' 语句块。

**else** 是一个可选的特殊的分支，当其他所有分支都匹配失败，并且提供了 else 分支时，将会进入 else 分支。

使用逗号表达式来匹配多个可能的值。

使用 in 表达式来匹配一个 Iterable 中的值；使用 of 表达式来匹配一个 struct/Map 的 values 中的值

```javascript
for (final i in range(0, 10)) {
  switch (i) {
    0 => {
      print('number: 0')
    }
    2, 3, 5, 7 => {
      print('prime: ${i}')
    }
    in [4, 9] => {
      print('square: ${i}')
    }
    else => {
      print('other: ${i}')
    }
  }
}
```
