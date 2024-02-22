import '../external/external_class.dart';
import '../error/error.dart';
import '../preinclude/console.dart';

class HTConsoleClass extends HTExternalClass {
  HTConsoleClass() : super('Console');

  @override
  dynamic instanceMemberGet(dynamic instance, String id) {
    final console = instance as Console;
    switch (id) {
      case 'console.log':
        return ({positionalArgs, namedArgs}) =>
            console.log(positionalArgs.first);
      // case 'console.readLine':
      //   return ({positionalArgs, namedArgs}) {
      //     if (positionalArgs.isNotEmpty) {
      //       stdout.write('${positionalArgs.first}');
      //     } else {
      //       stdout.write('>');
      //     }
      //     return stdin.readLineSync();
      //   };
      // case 'console.eraseLine':
      //   return ({positionalArgs, namedArgs}) =>
      //       stdout.write('\x1B[1F\x1B[1G\x1B[1K');
      // case 'console.clear':
      //   return ({positionalArgs, namedArgs}) =>
      //       stdout.write('\x1B[2J\x1B[0;0H');
      // case 'console.setTitle':
      //   return ({positionalArgs, namedArgs}) =>
      //       stdout.write('\x1b]0;${positionalArgs.first}\x07');
      default:
        throw HTError.undefined(id);
    }
  }
}
