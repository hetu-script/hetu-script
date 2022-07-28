import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  const root = 'example/script';
  final sourceContext = HTFileSystemResourceContext(root: root);
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();

  hetu.eval(r'''
    import 'inner/values.jsonc' as json

    print(json.name)
  ''');
}
