---
title: Installation
---

# Installation

Add the packages in your pubspec.yaml.

```yaml
dependencies:
  hetu_script: ^0.3.7
  # optional:
  # hetu_script_dev_tools: ^0.0.3+1
  # optional:
  # hetu_script_flutter: ^0.0.3
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

To handle module import from physical disk within the script, there's another package called: 'hetu_script_dev_tools'.

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

```kotlin
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

The 'hetu_script_dev_tools' package also provided a [REPL tool](../command_line_tool/readme.md#REPL) for quick testing.
