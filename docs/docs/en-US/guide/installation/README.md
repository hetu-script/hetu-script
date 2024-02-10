## hetu_script

Input this command in your terminal under the project folder to add the package to your project.

```
dart pub add hetu_script
```

Or use flutter version command:

```
flutter pub add hetu_script
flutter pub add hetu_script_flutter
```

## hetu_script_dev_tools

To import from another source file on your physical disk. Install the package 'hetu_script_dev_tools'.

```
dart pub add hetu_script_dev_tools
```

Then use the helper class **HTFileSystemResourceContext** provided by this package, to replace the default one:

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

content in 'import_test1.ht':

```javascript
import 'hello.ht' as h

function main {
  return h.hello()
}
```

content in 'hello.ht':

```javascript
function hello {
  return 'Hello, world!'
}
```

This package also provided a [REPL tool](../command_line_tool/readme.md#REPL) for quick testing.

## hetu_script_flutter

This package is for loading a script file from flutter assets.

```
dart pub add hetu_script_flutter
```

The default folder is 'scripts/', directly under your project root.

```yaml
assets:
  - scripts/main.ht
```

Use the helper class **HTAssetResourceContext** provided by this package, to replace the default one:

Then use the new method on Hetu class: **initFlutter** to init, instead the old method. The scripts you added in your pubspec.yaml will be pre-loaded. Note that this is an async function.

Then you can load a asset script file directly by **evalFile** method, you can omit the root in the path:

```dart
final sourceContext = HTAssetResourceContext(root: 'scripts/');
final hetu = Hetu(sourceContext: sourceContext);
await hetu.initFlutter();

final result = hetu.evalFile('main.ht', invoke: 'main');
```
