import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  try {
    hetu.eval('d');
  } catch (e) {
    print(e);
    final r = hetu.eval('Math.random()');
    print(r);
  }
}
