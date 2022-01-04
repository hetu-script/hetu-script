---
title: Installation
---

# Installation

Input this command in your terminal under the project folder to add the package to your project.

```
dart pub add hetu_script
```

Or use flutter version command:

```
flutter pub add hetu_script
flutter pub add hetu_script_flutter
```

## Flutter project

To load a script file from assets, add the script file's path into your pubspec.yaml like other assets.

The default folder is 'scripts/', directly under your project root.

```yaml
assets:
  - scripts/main.ht
```

You have to use the class **HTAssetResourceContext** provided by this package, to replace the default one:

Then use the new method on Hetu class: **initFlutter** to init instead the old method. Those scripts in assets will be pre-loaded. Note that this is an async function.

Then you can load a asset script file directly by **evalFile** method, you can omit the root part in the path:

```dart
final sourceContext = HTAssetResourceContext(root: 'scripts/');
final hetu = Hetu(sourceContext: sourceContext);
await hetu.initFlutter();

final result = hetu.evalFile('main.ht', invokeFunc: 'main');
```

## File system and module import

To handle module import from physical disk within the script. Install another package called: 'hetu_script_dev_tools'.

```
dart pub add hetu_script
```

You have to use the class **HTFileSystemResourceContext** provided by this package, to replace the default one:

```dart
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: '../../script/');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();
  final result = hetu.evalFile('import_test1.ht', invokeFunc: 'main');
  print(result);
}
```

content in 'import_test1.ht':

```javascript
import 'hello.ht' as h

fun main {
  return h.hello()
}
```

content in 'hello.ht':

```javascript
fun hello {
  return 'Hello, world!'
}
```

This package also provided a [REPL tool](../command_line_tool/readme.md#REPL) for quick testing.
