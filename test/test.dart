import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();

  final result = hetu.eval(r'''
        enum a {
          m
        }
        var b = a.m
        print(b)
    ''');

  print(result);
}
