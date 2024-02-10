import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init(externalFunctions: {
    'hello': () => {'greetings': 'greetings from Dart!'},
  });
  var hetuValue = hetu.eval(r'''
      external function hello
      var dartValue = hello()
      dartValue['reply'] = 'Hi, this is Hetu.'
      dartValue // the script will return the value of it's last expression
      ''');

  print('hetu value: $hetuValue');
}
