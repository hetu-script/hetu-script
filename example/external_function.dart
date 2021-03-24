import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTAstInterpreter();

  await hetu.init(externalFunctions: {
    'hello': (
            [List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
        {'greeting': 'hello'},
  });

  await hetu.eval(r'''
      external fun hello
      fun main {
        var dartValue = hello()
        print('dart value:', dartValue)
        dartValue['foo'] = 'bar'
        return dartValue
      }''');

  var hetuValue = hetu.invoke('main');

  print('hetu value: $hetuValue');
}
