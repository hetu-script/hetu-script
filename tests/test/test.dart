import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
      var a // a is null
      final value = a?.collection.dict.value // value is null and we won't get errors
      print(value)
    ''');
}
