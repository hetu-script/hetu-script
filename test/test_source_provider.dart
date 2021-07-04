import 'dart:io';

import 'package:hetu_script/hetu_script.dart';

void main() {
  final contextManager = HTContextManagerImpl();

  // final context = contextManager.getContext(Directory.current.path);
  final context = contextManager.getContext(Directory.current.path,
      includedFilter: [HTFilterConfig('script'), HTFilterConfig('test')]);
  // excludedFilter: [HTFilterConfig('test')]);

  print('root: ${context.root}');

  for (final item in context.included) {
    print(item);
  }

  final contextRoots = contextManager.computeRoots(context.included);

  print('computed:');

  for (final root in contextRoots) {
    print('root: $root');
  }
}
