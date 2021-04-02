import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      fun main {
        let i: List = [42]
        print(i.typeid)
      }
  ''', invokeFunc: 'main');
}
