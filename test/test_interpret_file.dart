import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  final result = await hetu.import('script/import_test.ht',
      config: InterpreterConfig(sourceType: SourceType.module),
      invokeFunc: 'importTest');

  print(result);
}
