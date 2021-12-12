import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
  struct Named {
    var name
    var age
    construct(name, age) {
      this.name = name
      this.age = age
    }
  }
  final n = Named('Jimmy', 17)
  print(n)
  ''', isScript: true);
}
