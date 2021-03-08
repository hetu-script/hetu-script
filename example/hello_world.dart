import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init(externalFunctions: {
    'dartHello': (HT_Instance instance, Map<String, dynamic> args) {
      return {'dartValue': 'hello'};
    },
  });
  hetu.eval('''
      external fun dartHello
      proc main {
        var dartValue = dartHello()
        print(typeof(dartValue))
        dartValue[\'foo\'] = \'bar\'
        print(dartValue)
      }
      ''', invokeFunc: 'main');
}
