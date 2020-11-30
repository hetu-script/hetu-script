import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init(externalFunctions: {
    'dartHello': (HT_Instance instance, List<dynamic> args) {
      return {'dartValue': 'hello'};
    },
  });
  hetu.eval(
      'external fun dartHello\n'
      'proc main {\n'
      '  var dartValue = dartHello()\n'
      '  print(typeof(dartValue))\n'
      '  dartValue[\'foo\'] = \'bar\'\n'
      '  print(dartValue)\n'
      '\n}',
      invokeFunc: 'main');
}
