## hetu_script

使用 dart pub add 命令来安装最新版本：

```
dart pub add hetu_script
```

对于 Flutter 项目，使用 flutter 版本的命令行工具：

```
flutter pub add hetu_script
flutter pub add hetu_script_flutter
```

## hetu_script_dev_tools

如果你需要在代码中，使用 import 语句导入你的文件系统上的另一个代码文件的内容。需要安装这个包。

```
dart pub add hetu_script_dev_tools
```

然后你需要使用 **HTFileSystemResourceContext** 辅助类, 在创建解释器时作为参数传入，替换掉默认的 sourceContext。

**HTFileSystemResourceContext** 的 root 参数是代码文件存放的根目录，如果不指定，会使用当前项目的根目录。

之后，你就可以使用解释器上的 **evalFile()** 方法来直接载入一个代码文件。你可以省略掉路径中 root 的部分。

```dart
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: '../../script/');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();
  final result = hetu.evalFile('import_test1.ht', invoke: 'main');
  print(result);
}
```

在代码中通过 import 语句引入其他代码文件的例子：

```javascript
import 'hello.ht' as h

function main {
  return h.hello()
}
```

另外，这个包还提供了一个 [**REPL**](../command_line_tool/readme.md#REPL) 工具用来辅助测试。

## hetu_script_flutter

对于想要在 Flutter APP 中引入作为 assets 资源文件的脚本的需求，可以安装这个包。

```
dart pub add hetu_script_flutter
```

```yaml
assets:
  - scripts/main.ht
```

和 hetu_script_dev_tools 类似，你需要用新的 **HTAssetResourceContext** 辅助类, 在创建解释器时作为参数传入，替换掉默认的 sourceContext。

**HTAssetResourceContext** 的 root 参数是代码文件存放的根目录，如果不指定，会使用当前项目**根目录下的 'scripts/'**。

在 Flutter APP 中，使用 **initFlutter()** 取代原本的 **init()** 来初始化解释器，这会提前载入你在 pubspec.yaml 中声明的代码资源文件。注意这是一个 async 方法，因此需要加上 await 关键字。

之后，你就可以使用解释器上的 **evalFile()** 方法来直接载入一个代码文件。你可以省略掉路径中 root 的部分。

```dart
final sourceContext = HTAssetResourceContext(root: 'scripts/');
final hetu = Hetu(sourceContext: sourceContext);
await hetu.initFlutter();

final result = hetu.evalFile('main.ht', invoke: 'main');
```
