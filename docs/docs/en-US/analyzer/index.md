---
title: Analyzer - Hetu Script Language
---

# Analyzer

Analyzer is a standalone utility class for analyze a Hetu source.

Example:

```dart
import 'package:hetu_script/analyzer.dart';

void main() {
  final hetu = HTAnalyzer();
  hetu.init();
  final result = hetu.eval(r'''
    var i = 'Hello, world!'
  ''', isScript: true);
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
