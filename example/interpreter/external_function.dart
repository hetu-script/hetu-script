import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HT_Interpreter(externalFunctions: {
    'hello': (HT_Interpreter interpreter,
        {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
      return {'greeting': 'hello'};
    },
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
