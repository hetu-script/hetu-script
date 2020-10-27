import 'dart:io';

final Map<String, String> paths = const {
  'core.ht': 'hetu_lib/core.ht',
  'value.ht': 'hetu_lib/value.ht',
  'system.ht': 'hetu_lib/system.ht',
  'console.ht': 'hetu_lib/console.ht',
  'math.ht': 'hetu_lib/math.ht',
  'help.ht': 'hetu_lib/help.ht',
};

void main() {
  String content = '/// The core librarys in Hetu.\n'
      '///\n'
      '/// Automatically generated based on files in "hetu_lib" folder.\n'
      'final Map<String, String> coreLibs = const {\n';
  var output = File('lib/src/core.dart');
  for (var file in paths.keys) {
    String data = File(paths[file]).readAsStringSync();
    // TODO: 脚本中的引号需要以反义字符替换
    content += '"$file": r"""' + data + '""",\n';
  }
  content += '};\n';

  output.writeAsStringSync(content);
}
