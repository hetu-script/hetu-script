import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var i = 42
  ''', asScript: true, globallyImport: true);
  hetu.eval(r'''
    var j = 'hello, guest no.${i}, next guest is no.${i+1}!'
  ''', asScript: true, globallyImport: true);
  hetu.eval(r'''
    print(j)
  ''', asScript: true, globallyImport: true);
}
