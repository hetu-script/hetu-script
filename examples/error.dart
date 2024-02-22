import 'package:hetu_script/hetu_script.dart';

void ext({positionalArgs, namedArgs}) {
  throw 'an error occured';
}

void main() {
  final hetu = Hetu(config: HetuConfig(showDartStackTrace: true));
  hetu.init(externalFunctions: {
    'ext': ext,
  });
  hetu.eval(r'''
      external function ext
      function main {
        ext()
      }
      ''', type: HTResourceType.hetuModule, invoke: 'main');
}
