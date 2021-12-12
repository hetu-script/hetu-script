import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
  struct Named {
    var name = 'Unity'
    var age = 17
  }
  final n = Named()
  n.age = 42
  print(n)
  print(Named)
  ''', isScript: true);
}
