import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = HTVM();

  // await hetu.init();

  final result = await hetu.eval(r'''
  class Name {
    var firstName = 'Adam'
    var familyName = 'Christ'

    fun toString() {
      return firstName + ' ' + familyName
    }
  }

  class Person {
    fun greeting {
      return 6 * 7
    }
    var name = Name()
  }

  fun main {
    // var j = Person()
    // var i
    // j.name.familyName = i = 'Luke'
    // j.name // Will use overrided toString function in user's class
    
  }
  ''', style: ParseStyle.module, invokeFunc: 'main');

  print(result);
}
