import 'package:hetu_script/hetu.dart';

void main() {
  hetu.init(workingDir: 'ht_excample');
  hetu.evalf('ht_excample\\type.ht', invokeFunc: 'main');
}
