import 'package:hetu_script/hetu_script.dart';

void ext(entity, {positionalArgs, namedArgs, typeArgs}) {
  throw 'an error occured';
}

void main() {
  final hetu = Hetu(config: InterpreterConfig(showDartStackTrace: true));
  hetu.init(externalFunctions: {
    'ext': ext,
  });
  hetu.eval(r'''
      external fun ext
      fun main {
        ext()
      }
      ''', type: HTResourceType.hetuModule, invokeFunc: 'main');
}
