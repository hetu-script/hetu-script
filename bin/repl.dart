import 'dart:io';
import 'package:hetu_script/hetu.dart';

const title = '河图脚本语言 0.0.1';
const version = '0.0.1';

void main() {
  stdout.write('\x1B]0;${title}\x07');

  hetu.init();

  print('\n${title}\n'
      '版本：${version}\n'
      '输入指令并按回车即可执行，输入\'quit\'退出REPL环境。'
      '以\'\\\'结尾的指令可以换行继续输入。'
      '注意：如果使用多行输入的方式，则最后一行之外的语句不能省略分号。');
  var quit = false;
  var currentFileName = DateTime.now().millisecondsSinceEpoch.toString();

  do {
    stdout.write('>>>');
    String input = stdin.readLineSync();
    if (input.endsWith('\\')) {
      input += '\n' + stdin.readLineSync();
    } else {
      input += '\n';
    }

    if ((input == 'exit') ||
        (input == 'quit') ||
        (input == 'close') ||
        (input == 'end') ||
        (input == '退出') ||
        (input == '离开') ||
        (input == '关闭') ||
        (input == '结束')) {
      print('正在退出...\n');
      quit = true;
    } else {
      var result;
      try {
        input += ';';
        hetu.eval(input, currentFileName, style: ParseStyle.function);
      } catch (e) {
        print(e);
      }
      if (result != null) print(result);
    }
  } while (!quit);
}
