import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
    final obj = {}
    obj
  ''');

  result['name'] = 'hetu';
  print(result);
}
