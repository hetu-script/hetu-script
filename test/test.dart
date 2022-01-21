import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final m = Map()
    m['aaa'] = 222

    final obj = prototype.fromJson(m)
    print(obj.toJson())
  ''');
}
