part of hetu_script_flutter;

extension HTFlutterExtension on Hetu {
  Future<void> initFlutter(
      {List<HTSource> preincludeModules = const [],
      List<HTExternalClass> externalClasses = const [],
      Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalFunctionTypedef> externalFunctionTypedef =
          const {}}) async {
    if (sourceContext is HTAssetResourceContext) {
      await (sourceContext as HTAssetResourceContext).init();
    }
    init(
        preincludeModules: preincludeModules,
        externalClasses: externalClasses,
        externalFunctions: externalFunctions,
        externalFunctionTypedef: externalFunctionTypedef);
  }
}
