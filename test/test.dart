import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    print('hello, world!')
      ''');
}
