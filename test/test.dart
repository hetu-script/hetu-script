import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
        fun test(a, [b]) {
          a = 4
          b = 3
          print(a,b)
        }

        test(1,2)
        
    ''');

  print(result);
}
