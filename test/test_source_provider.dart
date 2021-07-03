import 'dart:io';

import 'package:hetu_script/hetu_script.dart';

void main() {
  final sourceProvider = DefaultSourceProvider();

  final context = sourceProvider.getContext(Directory.current.path,
      includedFilter: [HTFilterConfig('script')],
      excludedFilter: [HTFilterConfig('test')]);

  print('root: ${context.root}');

  for (final item in context.included) {
    print(item);
  }
}
