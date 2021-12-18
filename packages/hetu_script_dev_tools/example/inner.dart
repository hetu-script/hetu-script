import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'example/script');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();

  hetu.evalFile('inner/inner.hts');
}
