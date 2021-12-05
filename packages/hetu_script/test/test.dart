import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    // var ht = {
    //   name: 'Hetu',
    //   age: 1
    // }

    bool r = false

    // print(ht.owns('toJson')) // false
    // print(ht.contains('toJson')) // true

    print(r)

  ''', asScript: true);
}
