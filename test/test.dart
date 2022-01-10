import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
      final obj = {
        name: 'Jay',
        age: 17,
      }

      for (final i of obj) {
        print(i)
      }
    ''');

  print(result);
}
