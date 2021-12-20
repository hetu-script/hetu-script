import 'package:flutter/material.dart';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_flutter/hetu_script_flutter.dart';

import 'src/code_editor.dart';

void main() async {
  // const root = 'scripts/';
  // final filterConfig = HTFilterConfig(root, extension: [
  //   HTResource.hetuModule,
  //   HTResource.hetuScript,
  //   HTResource.json,
  // ]);
  // final sourceContext = HTAssetResourceContext(
  //     root: root,
  //     includedFilter: [filterConfig],
  //     expressionModuleExtensions: [HTResource.json]);
  // _hetu = Hetu(sourceContext: sourceContext);
  final hetu = Hetu();
  await hetu.initFlutter();
  runApp(
    MaterialApp(
      title: 'Hetu Script Code Pad',
      theme: ThemeData.light().copyWith(
          scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbColor: MaterialStateProperty.all(Colors.grey),
      )),
      home: Scaffold(
        body: CodeEditor(
          interpreter: hetu,
        ),
      ),
    ),
  );
}
