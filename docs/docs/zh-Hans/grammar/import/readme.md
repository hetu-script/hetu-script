# 导入和导出

## 导入（import）

使用导入语句（import）来导入另一个代码文件中的声明。

你可以使用 '{}' 来提供一个标识符列表来限制引入的声明数量。

你可以使用 'as' 来提供一个别名，这会为导入的代码文件创造一个新的命名空间。

```javascript
import 'game.ht'
import { hello, calculator } from 'hello.ht' as h

fun main {
  h.greeting()
}
```

## 导出（export）

使用导出语句（export）来规定其他代码文件导入这个代码文件时所能导入的声明。

导出语句可以提供路径，此时意味着将另一个代码文件的内容先导入，再导出。

如果不提供路径，则意味着导出自己的声明，此时必须提供一个 '{}' 标识符列表。

```javascript
export {
  hello,
  calculator,
}

export 'game.ht'
export { hello } from 'hello.ht'
```

如果你没有提供任何导出声明。则会默认导出这个代码文件中所有非私有（标识符不是以 '\_' 开头）的顶层的声明。

## 动态导入（require）

河图 0.4.0 版本之后，可以使用类似 node.js 的 require 语句来动态导入一个代码文件。

```dart
final sourceContext = HTOverlayContext();
var hetu = Hetu(
  config: HetuConfig(
    normalizeImportPath: false,
  ),
  sourceContext: sourceContext,
);
hetu.init();
final source1 = HTSource(r'''
    var name = 'Richard Byson'
    var age = 42
''', fullName: 'source1.ht');
sourceContext.addResource(source1.fullName, source1);
hetu.eval(r'''
    final { name, age } = require('source1.ht');
    print(name, age)
''');
```

注意你必须以声明变量并给与其初始化值的方式来导入。单纯使用 require 并没有任何效果。

```javascript
require('source1.ht'); // 这样写不会有任何效果！
```

因为这种方式的导入会在运行时导入文件，因此你必须手动保证在代码运行之前，就已经在 sourceContext 中载入了对应路径名的文件。
