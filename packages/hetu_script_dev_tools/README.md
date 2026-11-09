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

A command line REPL tool for testing. You can install it globally with `dart install`:

```
dart install https://github.com/hetu-script/hetu-script.git --git-path packages/hetu_script_dev_tools
```

Or install from a local path:

```
dart install --source path /path/to/hetu-script/packages/hetu_script_dev_tools
```

Then you can use command line tool 'hetu' in any directory on your computer. (If you are facing any problems, please check this official document about [dart install](https://dart.dev/tools/dart-install))

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

## Auto-binding generator

This package includes an automatic binding generator for Dart classes, enums, and function typedefs marked with `@HTBinding()`.

### Using build_runner (recommended)

Add the dependencies to your project:

```yaml
dependencies:
  hetu_script: ^x.x.x

dev_dependencies:
  hetu_script_dev_tools: ^x.x.x
  build_runner: ^x.x.x
```

Annotate your Dart declarations:

```dart
import 'package:hetu_script/binding.dart';

@HTBinding()
class Person {
  String name;
  Person(this.name);

  void greeting(String tag) {
    print('Hi! $tag');
  }
}
```

Then run:

```bash
dart run build_runner build
```

The generator produces `.g.dart` binding files that can be registered with `Hetu.init(externalClasses: [...])`.

### Using the CLI

You can also generate bindings directly with the `hetu bind` command:

```bash
hetu bind -u lib/src -o gen/dart -s gen/ht
```

Options:

- `-u, --user-lib-paths`: Directories containing Dart source files to scan.
- `-o, --output`: Output directory for generated `.g.dart` files (default: `gen/dart`).
- `-s, --script-output`: Output directory for generated `.ht` files (default: `gen/ht`).
- `-i, --ignores`: File or class patterns to ignore.
- `-w, --whitelist`: Only process files matching these patterns.

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
