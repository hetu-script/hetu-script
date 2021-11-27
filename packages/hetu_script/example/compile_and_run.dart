import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();

  final appName = 'myApp1';

  final source = HTSource(r'''
    fun main {
      print('hello', 'world!')
    }
    ''');

  final bytes = hetu.compileSource(source,
      libraryName: appName, config: CompilerConfig(compileWithLineInfo: false));

  hetu.loadBytecode(bytes!, appName, invokeFunc: 'main');
}
