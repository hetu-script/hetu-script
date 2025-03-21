import 'package:hetu_script/hetu_script.dart';

void main() {
  final code = r'''
    {
      // names: {},

      entities: {
        //fdf
      }
    }
//     [
//       1
//       ,//dd
// //sdfs
//       3,
//     ]
''';
  final source = HTSource(code, type: HTResourceType.hetuScript);
  final parser = HTParserHetu();
  final result = parser.parseSource(source);
  for (final err in result.errors) {
    print(err);
  }
  for (final node in result.nodes) {
    print(node);
  }
}
