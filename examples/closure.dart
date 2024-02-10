import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
      function closure(func) {
        var i = 42
        function nested () {
          i = i + 1
          print(func(i))
        }
        return nested
      }

      var func = closure( (n) => n * n )
      func()
      ''');
}
