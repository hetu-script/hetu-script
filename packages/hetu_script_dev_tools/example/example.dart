import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: '../../script/');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();
  final result1 = hetu.evalFile('import_test2.ht', invocation: 'main');
  print(result1);

  // final result2 = hetu.evalFile('import_test.ht', invocation: 'importTest');
  // print(result2);

  // final result3 = hetu.evalFile('mod.ht', invocation: 'modTest');
  // print(result3);
}
