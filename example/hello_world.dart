import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init(externalFunctions: {
    'dartHello': ({List<dynamic> positionalArgs, Map<String, dynamic> namedArgs, HT_Instance instance}) {
      return {'dartValue': 'hello'};
    },
  });
  hetu.eval('''
      external fun dartHello
      fun main {
        var dartValue = dartHello()
        print(typeof(dartValue))
        dartValue[\'foo\'] = \'bar\'
        print(dartValue)
      }
      ''', invokeFunc: 'main');
}
