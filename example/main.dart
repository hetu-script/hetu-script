import 'package:hetu_script/hetu.dart';

void main() {
  Hetu.init(preloadDir: 'script');
  Hetu.evalf('test\\test.hs', invokeFunc: 'main');
}
