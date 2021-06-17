import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu(config: InterpreterConfig(sourceType: SourceType.script));
  await hetu.init();
  await hetu.eval(r'''
    var i = 42
  ''');
  await hetu.eval(r'''
    var j = 'hello, guest no.${i}, next guest is no.${i+1}!'
  ''');
  await hetu.eval(r'''
    print(j)
  ''');
}
