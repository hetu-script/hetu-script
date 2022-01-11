import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
      final list = [1,2,3,4,5,6,7,8,9,10]

      for (final i in list) {
        if (i.isEven) continue
        print(i)
      }
    ''');

  print(result);
}
