import 'package:flutter/material.dart';

import 'src/code_editor.dart';

void main() async {
  runApp(
    MaterialApp(
      title: 'Hetu Script Code Pad',
      theme: ThemeData.light().copyWith(
          scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbColor: MaterialStateProperty.all(Colors.grey),
      )),
      home: const Scaffold(
        body: CodeEditor(),
      ),
    ),
  );
}
