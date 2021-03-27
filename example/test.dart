import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();

  await hetu.init();

  await hetu.eval(r'''
  class Profile {
    var age = 17
  }

  class Person {
    var p = { 'age' : 17 }
  }

  fun main {
    // var p = Person()
    // print(++p.p['age'])
    // print(p.p)
    
    // if (1 < ((3 + 4) / 2)) print('hi')

    // print(num.parse('42'))

    var prof = 'farmer'

    // print('  ' +  prof  +   ': ' )

    print( true && (1 is num) && ( 3 > 2))
  }
  ''', style: ParseStyle.module, invokeFunc: 'main');
}
