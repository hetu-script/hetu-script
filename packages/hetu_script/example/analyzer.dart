import 'package:hetu_script/analyzer.dart';
import 'package:hetu_script/errors.dart';

void main() {
  final hetu = HTAnalyzer();
  hetu.init();
  final result = hetu.eval(r'''
    var i = 'Hello, world!'
  ''');
  if (result != null) {
    if (result.errors.isNotEmpty) {
      for (final error in result.errors) {
        if (error.severity >= ErrorSeverity.error) {
          print('Error: $error');
        } else {
          print('Warning: $error');
        }
      }
    } else {
      print('Analyzer found 0 problem.');
    }
  } else {
    print('Unkown error occurred during analysis.');
  }
}
