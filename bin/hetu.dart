import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:hetu_script/hetu.dart';
import 'common.dart';

void main(List<String> args) {
  hetu.init(displayLoadingInfo: false);
  if (args.isNotEmpty) {
    if ((args.first == '--help') || (args.first == '-h')) {
      String doc = File('cli_help.txt').readAsStringSync();
      print(doc);
    } else if ((args.first == '--version') || (args.first == '-v')) {
      print('${Hetu_Env.title} ${Hetu_Env.version}');
      print('${Hetu_Env.cliTitle} ${Hetu_Env.cliVersion}');
    } else {
      try {
        var style = ParseStyle.function;
        String libname = HS_Common.Global;
        String entrance;

        if (args.length > 1) {
          var option = args[1];
          if (option == '-l') {
            style = ParseStyle.library;
          } else if (option == '-p') {
            style = ParseStyle.library;
            entrance = HS_Common.mainFunc;
          }
        }

        hetu.evalf(args.first, displayLoadingInfo: false, libName: libname, style: style, invokeFunc: entrance);
      } catch (e) {
        print(e);
      }
    }
  } else {
    String doc = File('cli_help.txt').readAsStringSync();
    print(doc);
  }
}
