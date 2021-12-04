import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var ht = {
      name: 'Hetu',
      age: 1
    }

    print(ht.contains('toJson'))
  ''', asScript: true);
}
