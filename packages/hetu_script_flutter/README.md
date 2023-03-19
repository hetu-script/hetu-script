# Hetu Script for Flutter

This is an extension for [hetu_script](https://pub.dev/packages/hetu_script).

## Getting started

To load a script file from assets, add the script file's path into your pubspec.yaml like other assets.

The default folder is 'scripts/', directly under your project root.

```yaml
assets:
  - scripts/main.ht
```

Then those script will be pre-loaded by the new init method on Hetu class: [initFlutter].

You don't need to use old [init]. Also note that this is an async function.

You can load a asset script file by [evalFile] method:

```dart
final hetu = Hetu();
await hetu.initFlutter();

final result = hetu.evalFile('main.ht', invoke: 'main');
```
