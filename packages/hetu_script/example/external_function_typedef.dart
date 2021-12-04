import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';

typedef DartFunction = int Function(int a, int b);

int hetuAdd(DartFunction func) {
  return func(6, 7);
}

void main() {
  var hetu = Hetu();

  hetu.init(externalFunctions: {
    'hetuAdd': (HTEntity entity,
        {List<dynamic> positionalArgs = const [],
        Map<String, dynamic> namedArgs = const {},
        List<HTType> typeArgs = const []}) {
      return hetuAdd(positionalArgs.first);
    },
  }, externalFunctionTypedef: {
    'DartFunction': (HTFunction function) {
      return (int a, int b) {
        // must convert the return type here to let dart know its return value type.
        return function.call(positionalArgs: [a, b]) as int;
      };
    },
  });

  hetu.eval(r'''
      external fun hetuAdd(func)
      fun [DartFunction] namedAdd(a: num, b: num) -> num {
        return a + b
      }
      fun main {
        return hetuAdd(fun [DartFunction] (a: num, b: num) -> num {
          return a + b
        })
      }''');

  var result = hetu.invoke('main');

  print(result);
}
