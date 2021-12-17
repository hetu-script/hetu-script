import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
      var a = {
        collection: {}
      }
      final value = a.collection.value() // value is null and we won't get errors
      print(value)
    ''');
}
