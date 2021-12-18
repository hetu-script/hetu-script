import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  const root = 'example/script';
  final filterConfig = HTFilterConfig(root, extension: [
    HTResource.hetuModule,
    HTResource.hetuScript,
    HTResource.json,
  ]);
  final sourceContext = HTFileSystemResourceContext(
      root: root,
      includedFilter: [filterConfig],
      expressionModuleExtensions: [HTResource.json]);
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();

  hetu.evalFile('json.hts');
}