import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  // Run this program from terminal.

  final sourceContext = HTFileSystemSourceContext(root: 'script');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();
  hetu.loadExtensions();

  // hetu.evalFile('battle1.ht', invokeFunc: 'main');
  hetu.evalFile('battle2.ht', invokeFunc: 'main');
}
