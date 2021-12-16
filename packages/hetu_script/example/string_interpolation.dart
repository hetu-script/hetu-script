import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var i = 42
  ''', isModule: true, globallyImport: true);
  hetu.eval(r'''
    var j = 'hello, guest no.${i}, next guest is no.${i+1}!'
  ''', isModule: true, globallyImport: true);
  hetu.eval(r'''
    print(j)
  ''', isModule: true, globallyImport: true);
}
