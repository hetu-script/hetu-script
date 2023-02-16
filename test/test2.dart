import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();

  final r = hetu.eval(r'''
  class test {
    static fun hello {
      print('hello')
    }
  }
  ''');

  hetu.invoke('hello', namespaceName: 'test');

  print(hetu.lexicon.stringify(r));
}
