import 'dart:io';

final Map<String, String> builtInModules = const {
  'hetu:core': '../../lib/core/core.ht',
  'hetu:value': '../../lib/core/value.ht',
  'hetu:system': '../../lib/core/system.ht',
  'hetu:math': '../../lib/core/math.ht',
  'hetu:help': '../../lib/core/help.ht',
};

final Map<String, String> optionalModules = const {};

void main() {
  stdout.write('Converting files in \'lib\' folder into Dart strings...');
  final output = StringBuffer();
  output.write('''
/// This file has been automatically generated 
/// from files in [hetu_lib] folder.
/// Please do not edit manually.
///
/// The pre-included modules of Hetu scripting language.
final Map<String, String> builtInModules = const {
''');
  final file = File('lib/interpreter/buildin//hetu_lib.dart');
  for (final key in builtInModules.keys) {
    final data = File(builtInModules[key]!).readAsStringSync();
    output.writeln("  '$key': r'''" + data + "''',");
  }
  output.writeln('};');
  final content = output.toString();
  file.writeAsStringSync(content);
  stdout.writeln(' done!');
}
