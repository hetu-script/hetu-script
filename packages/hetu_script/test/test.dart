import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    // var list = [5, 6]
    // var ht = [1, 2, ...[3, 4], ...list]
    // print(ht)

    // fun someFunc(a, b) {
    //   return a + b
    // }
    // var list = [5, 6]
    // print(someFunc(...list))

    var name = {
      familyName: 'Hord',
      firstName: 'Luk'
    }
    var person = {
      ...name,
      age: 23,
    }
    print(person)
  ''', isScript: true);
}
