# 语法分析

**注意: 河图的类型系统相关工具并不完整，并不建议在生产中使用 Analyzer 或者打开 HetuConfig 上的 doStaticAnalysis 和 computeConstantExpression 开关。**

河图提供了一个单独的工具类 Analyzer，可以在不运行代码的前提下分析河图脚本的错误。下面是一个简单的例子：

```dart
import 'package:hetu_script/analyzer.dart';

void main() {
  final hetu = HTAnalyzer();
  hetu.init();
  final result = hetu.eval(r'''
    var i = 'Hello, world!'
  ''');
  if (result != null) {
    if (result.errors.isNotEmpty) {
      print('Analyzer found ${result.errors.length} problems:');
      for (final err in result.errors) {
        print(err);
      }
    } else {
      print('Analyzer found 0 problem.');
    }
  } else {
    print('Unkown error occurred during analysis.');
  }
}

```
