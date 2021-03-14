import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = HT_VM(debugMode: true);

  hetu.eval(r'''
  1 + 2
  ''', style: ParseStyle.function);
}
