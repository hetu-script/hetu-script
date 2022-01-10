import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
      fun getMeaning => 42
      struct Person {
        construct {
          this.meaning = getMeaning()
        }
      }
      var p = Person()
      print(p)
    ''');

  print(result);
}
