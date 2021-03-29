import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();

  await hetu.init();

  await hetu.eval(r'''
class Person {
  var name: str = 'just a guy';
}


class Jimmy extends Person {
  construct {
    name = 'Jimmy'
  }
  fun greeting {
    print("Hi! I'm", name)
  }
}

fun main {
  var j = Jimmy()
  j.greeting()
}
  ''', style: ParseStyle.module, invokeFunc: 'main');
}
