import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
        var id = 'terrain'

        var tile = {
          id,
        }

        print(tile)
        
    ''');

  print(result);
}
