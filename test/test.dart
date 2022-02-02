import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final a = Set(1,2,3)
    final b = jsonify(a)
    print(b)
  ''');
}
