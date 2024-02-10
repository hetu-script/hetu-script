# Hetu Script developer tools

This is an extension for [hetu_script](https://pub.dev/packages/hetu_script).

## File system source context

Within the script, if you imported from other script file on your physical disk, you should use [HTFileSystemResourceContext] instead of the default implementation.

```dart
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'script/');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();
  final result = hetu.evalFile('script.ht', invoke: 'main');
  print(result);
}
```

## Command line tool

A command line REPL tool for testing. You can activate by the following command:

```
dart pub global activate hetu_script_dev_tools
// or you can use a git url or local path:
// dart pub global activate --source path G:\_dev\hetu-script\dev-tools
```

Then you can use command line tool 'hetu' in any directory on your computer. (If you are facing any problems, please check this official document about [pub global activate](https://dart.dev/tools/pub/cmd/pub-global))

More information about the command line tool can be found by enter [hetu -h].

If no arguments is provided, enter REPL mode.

In REPL mode, every exrepssion you entered will be evaluated and print out immediately.

If you want to write multiple line in REPL mode, use '\\' to end a line.

```typescript
>>>var a = 42
>>>a
42
>>>function hello {\
return a }
>>>hello
function hello() -> any // repl print
>>>hello()
42 // repl print
>>>
```

## Console extension on Hetu api

This packages also added a console extension to Hetu's internal api, for writing console apps.

Example:

```dart
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

// Run this program from terminal.
void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'example/script');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();
  hetu.loadExtensions(['console']);

  hetu.evalFile('console.ht', invoke: 'main');
}
```

Content in 'console.ht'

```javascript
function main {
  final username = Console.getln('What\'s your name? ...')
  print('Hi! ${username}.')
}
```

Output:

```
What's your name? ...Ryan
Hi! Ryan.
```
