import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  final bytes = hetu.compile(r'''
    fun main {
      print('hello', 'world!')
    }
    ''', config: CompilerConfig(removeLineInfo: false));

  hetu.interpreter
      .loadBytecode(bytes: bytes, module: 'myModule', invocation: 'main');
}
