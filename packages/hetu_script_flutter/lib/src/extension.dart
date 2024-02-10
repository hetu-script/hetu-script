import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';
import 'package:hetu_script/value/function/function.dart';

import 'assets_resource_context.dart';

extension HTFlutterExtension on Hetu {
  Future<void> initFlutter({
    bool useDefaultModuleAndBinding = true,
    Map<String, Function> externalFunctions = const {},
    Map<String, Function Function(HTFunction)> externalFunctionTypedef =
        const {},
    List<HTExternalClass> externalClasses = const [],
  }) async {
    if (sourceContext is HTAssetResourceContext) {
      await (sourceContext as HTAssetResourceContext).init();
    }
    init(
        useDefaultModuleAndBinding: useDefaultModuleAndBinding,
        externalFunctions: externalFunctions,
        externalFunctionTypedef: externalFunctionTypedef,
        externalClasses: externalClasses);
  }
}
