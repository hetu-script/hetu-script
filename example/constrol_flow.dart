import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = HTVM();

  await hetu.init(coreModule: false, coreExternalClasses: false);

  await hetu.eval(r'''
  external fun print(... arg)
  fun main {
    var i = 0
    while (i < 10) {
      ++i
      var while_block;
      if (i < 5) {
        print(i)
      } else {
        break;
      }
    }
  }
  ''', invokeFunc: 'main');
}
