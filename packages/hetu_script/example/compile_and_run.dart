import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  final moduleName = 'myModule';
  final bytes = hetu.compile(r'''
    fun main {
      print('hello', 'world!')
    }
    ''', moduleName: moduleName, config: CompilerConfig(removeLineInfo: false));

  hetu.interpreter
      .loadBytecode(bytes: bytes, moduleName: moduleName, invokeFunc: 'main');
}
