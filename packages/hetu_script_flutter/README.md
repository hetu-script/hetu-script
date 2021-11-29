# Hetu Script for Flutter

## Features

Read script from assets dirrectly.

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
