import 'package:hetu_script/hetu_script.dart';

void main() {
  Map dartMapValue = {'greetings': 'greetings from Dart!'};

  final hetu = Hetu();
  hetu.init(externalFunctions: {
    'getValue': () => dartMapValue,
    'setValue': (Map value) => dartMapValue = value,
  });
  hetu.eval(r'''
      external function getValue
      external function setValue(key)

      final dartValue = getValue()
      print(dartValue)
      final newMap = Map()
      newMap['reply'] = 'Hi, this is Hetu.'
      setValue(newMap)
      
      final newDartValue = getValue()
      print(newDartValue)
      ''');
}
