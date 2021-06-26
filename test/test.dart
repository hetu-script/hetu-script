import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(config: InterpreterConfig(sourceType: SourceType.script));
  hetu.init();
  final result = hetu.eval(r'''
    a * 1
  ''');
  print(result);
}
