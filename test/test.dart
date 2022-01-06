import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''

  var generatedIndexes = 0
  while (generatedIndexes++ < 10) {
    
    print(generatedIndexes)
  }
    ''');

  print(result);
}
