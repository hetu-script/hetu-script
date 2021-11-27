import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemSourceContext(root: '../../script/');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();
  final result = hetu.evalFile('import_test2.ht', invokeFunc: 'main');
  print(result);

  final result2 = hetu.evalFile('import_test.ht', invokeFunc: 'importTest');
  print(result2);
}
