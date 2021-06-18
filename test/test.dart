import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu(config: InterpreterConfig(sourceType: SourceType.script));
  await hetu.init();
  final result = await hetu.eval(r'''
    var list = [1,2,3]

    for (var item in list) {
      print(item)
    }

  ''');
  print(result);
}
