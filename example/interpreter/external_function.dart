import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = HT_Interpreter(externalFunctions: {
    'hello': () => {'greeting': 'hello'},
  });
  hetu.eval(r'''
      external fun hello
      fun main {
        var dartValue = hello()
        print(typeof(dartValue))
        dartValue['foo'] = 'bar'
        print(dartValue)
      }''', invokeFunc: 'main');
}
