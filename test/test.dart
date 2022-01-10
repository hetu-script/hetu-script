import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();

  final result = hetu.eval(r'''
    late a
    // print(a) // Error: [a] is not initialized yet.
    a = 42
    print(a)
    // a = 'dragon' // Error: [a] is immutable.
    ''');

  print(result);
}
