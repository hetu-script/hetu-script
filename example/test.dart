import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      print(-5)
    ''', style: ParseStyle.block);
}
