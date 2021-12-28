import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
              var list = [5, 6]
        var ht = [1, 2, ...[3, 4], ...list]
        print(stringify(ht))
    ''');
}
