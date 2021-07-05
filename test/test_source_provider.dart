import 'dart:io';

import 'package:hetu_script/hetu_script.dart';

void main() {
  final context = HTContext(
      rootPath: Directory.current.path,
      includedFilter: [HTFilterConfig('script')]);

  // excludedFilter: [HTFilterConfig('test')]);

  print('root: ${context.root}');

  for (final item in context.included) {
    print(item);
  }

  // final contextRoots = contextManager.computeRoots(context.included);

  // print('computed:');

  // for (final root in contextRoots) {
  //   print('root: $root');
  // }
}
