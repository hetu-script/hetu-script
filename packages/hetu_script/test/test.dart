import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var ht = {
      name: 'Hetu',
      age: 1
    }
    var ht2 = ht.clone()
    ht2.name = 'Harry'
    print(ht)
    print(ht2)
  ''', isScript: true);
}
