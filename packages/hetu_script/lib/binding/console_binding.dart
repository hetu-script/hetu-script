import 'dart:io';

import '../external/external_class.dart';
import '../error/error.dart';

class HTConsoleClass extends HTExternalClass {
  HTConsoleClass() : super('Console');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'Console.write':
        return ({positionalArgs, namedArgs}) =>
            stdout.write(positionalArgs.first);
      case 'Console.writeln':
        return ({positionalArgs, namedArgs}) =>
            stdout.writeln(positionalArgs.first);
      case 'Console.getln':
        return ({positionalArgs, namedArgs}) {
          if (positionalArgs.isNotEmpty) {
            stdout.write('${positionalArgs.first}');
          } else {
            stdout.write('>');
          }
          return stdin.readLineSync();
        };
      case 'Console.eraseLine':
        return ({positionalArgs, namedArgs}) =>
            stdout.write('\x1B[1F\x1B[1G\x1B[1K');
      case 'Console.setTitle':
        return ({positionalArgs, namedArgs}) =>
            stdout.write('\x1b]0;${positionalArgs.first}\x07');
      case 'Console.clear':
        return ({positionalArgs, namedArgs}) =>
            stdout.write('\x1B[2J\x1B[0;0H');
      default:
        throw HTError.undefined(id);
    }
  }
}
