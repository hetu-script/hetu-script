import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(config: InterpreterConfig(sourceType: SourceType.module));
  hetu.init();
  final result = hetu.evalFile('script/import_test2.ht', invokeFunc: 'main');

  print(result);
}
