import 'package:hetu_script/hetu_script.dart';

import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final context = HTFileSystemContext(
      root: '../', includedFilter: [HTFilterConfig('script')]);

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
