import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu(config: InterpreterConfig(showDartStackTrace: true));
  hetu.init(externalFunctions: {
    'hello': () => throw 'error!',
  });
  var hetuValue = hetu.eval(r'''
      external fun hello
      var dartValue = hello()
      dartValue['reply'] = 'Hi, this is Hetu.'
      dartValue // the script will return the value of it's last expression
      ''');

  print('hetu value: $hetuValue');
}
