import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu(config: InterpreterConfig(sourceType: SourceType.script));
  hetu.init();
  hetu.eval(r'''
    var i = 42
  ''');
  hetu.eval(r'''
    var j = 'hello, guest no.${i}, next guest is no.${i+1}!'
  ''');
  hetu.eval(r'''
    print(j)
  ''');
}
