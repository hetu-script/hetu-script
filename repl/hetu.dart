import 'dart:io';

import 'package:hetu_script/hetu.dart';

abstract class Hetu_Env {
  static const title = '河图脚本语言';
  static const version = '版本：0.0.1';
}

const cli_help = '''
        以脚本模式解释一个文本文件

        调用方法：hetu [选项] [文件名] [函数名]
        -h, --help                            显示此帮助文本
        -v, --version                         显示版本号
        -r, --repl                            进入repl模式
        -l                                    以库模式解释
          [-c], [--class xxx]				
          [-f], [--function xxx]
        ''';

void main(List<String> args) async {
  try {
    var interpreter = await HetuEnv.init();

    if (args.isNotEmpty) {
      if ((args.first == '--help') || (args.first == '-h')) {
        print(cli_help);
      } else if ((args.first == '--version') || (args.first == '-v')) {
        print('${Hetu_Env.title} ${Hetu_Env.version}');
      } else if ((args.first == '--repl') || (args.first == '-r')) {
        stdout.write('\x1B]0;${Hetu_Env.title} ${Hetu_Env.version}\x07');
        print('\n${Hetu_Env.title} ${Hetu_Env.version}\n'
            '输入指令并按回车即可执行，输入\'quit\'退出REPL环境。以\'\\\'结尾的指令可以换行继续输入。\n');
        var quit = false;

        while (!quit) {
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
            quit = true;
          } else {
            if (input.endsWith('\\')) {
              input += '\n' + stdin.readLineSync();
            }

            dynamic result;
            try {
              result = await interpreter.eval(input, 'REPL', style: ParseStyle.function);
              if (result != null) print(result);
            } catch (e) {
              print(e);
            }
          }
        }
      } else if (args.first == '-s') {
        await interpreter.evalf(args.first, style: ParseStyle.function);
      } else {
        await interpreter.evalf(args.first, style: ParseStyle.library, invokeFunc: env.lexicon.defaultProgramMainFunc);
      }
    } else {
      print(cli_help);
    }
  } catch (e) {
    print(e);
  }
}
