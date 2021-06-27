import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu(config: InterpreterConfig(sourceType: SourceType.script));
  hetu.init();
  hetu.eval(r'''
    var i = 42
    ++i
  ''');
}

// import 'package:hetu_script/hetu_script.dart';

// void main() {
//   final hetu =
//       HTAnalyzer(config: AnalyzerConfig(sourceType: SourceType.script));
//   hetu.init();
//   final result = hetu.eval(r'''
//     var i = 'Hello, world!'
//   ''');
//   if (result != null) {
//     if (result.errors.isNotEmpty) {
//       print('Analyzer found ${result.errors.length} problems:');
//       for (final err in result.errors) {
//         print(err);
//       }
//     } else {
//       print('Analyzer found 0 problem.');
//     }
//   } else {
//     print('Unkown error occurred during analysis.');
//   }
// }
