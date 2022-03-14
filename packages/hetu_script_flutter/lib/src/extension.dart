part of hetu_script_flutter;

extension HTFlutterExtension on Hetu {
  Future<void> initFlutter({
    bool useDefaultModuleAndBinding = true,
    HTLocale? locale,
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
        locale: locale,
        externalFunctions: externalFunctions,
        externalFunctionTypedef: externalFunctionTypedef,
        externalClasses: externalClasses);
  }
}
