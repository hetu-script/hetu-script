import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.import('script/import_test2.ht',
      config: InterpreterConfig(sourceType: SourceType.module),
      invokeFunc: 'main');
}
