import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();

  await hetu.init();

  await hetu.eval(r'''
  var year = 2021

  class Person {
    construct {
      yesr = 2077
    }
  }

  fun main {
    var p = Person()

    print(year)
  }
  ''', style: ParseStyle.module, invokeFunc: 'main');
}
