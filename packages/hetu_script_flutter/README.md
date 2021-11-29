# Hetu Script for Flutter

This is an extension for [hetu_script](https://pub.dev/packages/hetu_script).

## Features

With this package, you can now read hetu script from assets.

## Getting started

Use [initFlutter] instead of [init]. Also note that this is an async function.

```dart
final hetu = Hetu();
await hetu.initFlutter();

hetu.eval(r'''
  fun main {
    print('hello Flutter!')
  }
''', invokeFunc: 'main');

```
