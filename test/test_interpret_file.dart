import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu(config: InterpreterConfig(sourceType: SourceType.module));
  await hetu.init();
  final result =
      await hetu.evalFile('script/import_test2.ht', invokeFunc: 'main');

  print(result);
}
