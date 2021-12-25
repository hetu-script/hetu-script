import 'dart:io';

final Map<String, String> builtInModules = const {
  'hetu:core': '../../lib/core/core.ht',
  'hetu:value': '../../lib/core/value.ht',
  'hetu:async': '../../lib/core/async.ht',
  'hetu:system': '../../lib/core/system.ht',
  'hetu:math': '../../lib/core/math.ht',
};

final Map<String, String> optionalModules = const {
  'hetu:tools': '../../lib/core/tools.ht',
};

void main() {
  stdout.write('Converting files in \'lib\' folder into Dart strings...');
  final output = StringBuffer();
  output.writeln('''
/// This file has been automatically generated
/// from files in [hetu_lib] folder.
/// Please do not edit manually.
part of '../abstract_interpreter.dart';

/// The pre-included modules of Hetu scripting language.
final List<HTSource> preIncludeModules = [''');
  final file = File('lib/interpreter/preinclude/preinclude_modules.dart');
  for (final key in builtInModules.keys) {
    final data = File(builtInModules[key]!).readAsStringSync();
    output.writeln(
        "  HTSource(r'''$data''', name: '$key', type: ResourceType.hetuModule),");
  }
  output.writeln('];');
  final content = output.toString();
  file.writeAsStringSync(content);
  stdout.writeln(' done!');
}
