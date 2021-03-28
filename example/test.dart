import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      for (var i=0; i<4; ++i) {
        print(i)
      }
    ''', style: ParseStyle.block);
}
