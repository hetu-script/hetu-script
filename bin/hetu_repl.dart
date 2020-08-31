import 'dart:io';
import 'package:hetu_script/hetu.dart';
import 'common.dart';

void main() {
  stdout.write('\x1B]0;${Hetu_Env.title}\x07');

  hetu.init();

  print('\n${Hetu_Env.title} ${Hetu_Env.version}\n'
      '输入指令并按回车即可执行，输入\'quit\'退出REPL环境。以\'\\\'结尾的指令可以换行继续输入。\n');
  var quit = false;
  var currentFileName = DateTime.now().millisecondsSinceEpoch.toString();

  do {
    stdout.write('>>>');
    String input = stdin.readLineSync();

    if ((input == 'exit') ||
        (input == 'quit') ||
        (input == 'close') ||
        (input == 'end') ||
        (input == '退出') ||
        (input == '离开') ||
        (input == '关闭') ||
        (input == '结束')) {
      print('河图脚本Repl环境已退出。\n');
      quit = true;
    } else {
      if (input.endsWith('\\')) {
        input += '\n' + stdin.readLineSync();
      }

      dynamic result;
      try {
        result = hetu.eval(input, currentFileName, style: ParseStyle.function);
      } catch (e) {
        print(e);
      }
      if (result != null) print(result);
    }
  } while (!quit);
}
