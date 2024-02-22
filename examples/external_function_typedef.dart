import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';

typedef DartFunction = int Function(int a, int b);

int hetuAdd(DartFunction func) {
  return func(6, 7);
}

void main() {
  final hetu = Hetu();

  hetu.init(externalFunctions: {
    'hetuAdd': ({positionalArgs, namedArgs}) {
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
      external function hetuAdd(func)
      function [DartFunction] namedAdd(a: num, b: num) -> num {
        return a + b
      }
      function main {
        return hetuAdd(function [DartFunction] (a: num, b: num) -> num {
          return a + b
        })
      }''');

  var result = hetu.interpreter.invoke('main');

  print(result);
}
