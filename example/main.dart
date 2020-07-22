import 'package:hetu_script/hetu.dart';

void main() {
  Hetu.init(preloadDir: 'script');
  Hetu.evalf('test\\calculator.hs', invokeFunc: 'main');
}
