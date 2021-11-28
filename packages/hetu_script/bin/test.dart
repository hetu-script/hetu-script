import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();

  hetu.eval(r'''
    fun print1(obj) {
      print(obj)
    }

    fun test {
      print1(aaa)
    }
  ''', invokeFunc: 'test');
}
