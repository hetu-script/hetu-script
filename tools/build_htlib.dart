import 'dart:io';

final Map<String, String> coreModules = const {
  'core.ht': 'hetu_lib/core/core.ht',
  'value.ht': 'hetu_lib/core/value.ht',
  'system.ht': 'hetu_lib/core/system.ht',
  'console.ht': 'hetu_lib/core/console.ht',
  'math.ht': 'hetu_lib/core/math.ht',
  'help.ht': 'hetu_lib/core/help.ht',
};

final Map<String, String> optionalModules = const {};

void main() {
  stdout.write('Converting files in \'hetu_lib\' folder into Dart strings...');
  var content = '''
/// The pre-packaged modules of Hetu scripting language.
///
/// Automatically generated based on files in \'hetu_lib\' folder.
final Map<String, String> coreModules = const {
      ''';
  final output = File('lib/src/hetu_lib.dart');
  for (final file in coreModules.keys) {
    final data = File(coreModules[file]!).readAsStringSync();
    // TODO: 脚本中的引号需要以反义字符替换
    content += "'$file': r'''" + data + "''',\n";
  }
  content += '};\n';

  output.writeAsStringSync(content);
  print('done.');
}
