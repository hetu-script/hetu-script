import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var i = 42
  ''', type: SourceType.script);
  hetu.eval(r'''
    var j = 'hello, guest no.${i}, next guest is no.${i+1}!'
  ''', type: SourceType.script);
  hetu.eval(r'''
    print(j)
  ''', type: SourceType.script);
}
