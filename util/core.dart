import 'dart:io';

final List<String> coreFiles = const [
  'hetu_lib/core.ht',
  'hetu_lib/value.ht',
  'hetu_lib/system.ht',
  'hetu_lib/console.ht',
];

final List<String> extraFiles = const [
  'hetu_lib/math.ht',
  'hetu_lib/help.ht',
];

void main() {
  String content;
  var output = File('lib/src/core.dart');
  for (var path in coreFiles) {
    String data = File(path).readAsStringSync();
  }

  output.writeAsStringSync(content);
}
