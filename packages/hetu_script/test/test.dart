import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
  struct Named {
    static var race = 'Human'
    var name
    construct(name) {
      this.name = name
    }
  }
  final n = Named('Jimmy')
  Named.race = 'Dragon'
  print(n.race) // 'Dragon'
  ''', isScript: true);
}
