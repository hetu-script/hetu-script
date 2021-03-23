import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = HTVM();

  // await hetu.init();

  final result = await hetu.eval(r'''
  class Person {
    fun greeting {
      return 6 * 7
    }
    var name = 'Adam'
  }

  fun main {
    var j = Person()
    j.name = 'Jimmy'
    j.name
  }
  ''', style: ParseStyle.module, invokeFunc: 'main');

  print(result);
}
