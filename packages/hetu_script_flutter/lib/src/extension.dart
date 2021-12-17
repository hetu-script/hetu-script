part of hetu_script_flutter;

extension HTFlutterExtension on Hetu {
  Future<void> initFlutter(
      {List<HTSource> preincludeModules = const [],
      List<HTExternalClass> externalClasses = const [],
      Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalFunctionTypedef> externalFunctionTypedef =
          const {}}) async {
    final assetsContext = HTAssetsSourceContext();
    await assetsContext.init();

    sourceContext = assetsContext;

    init(
        preincludeModules: preincludeModules,
        externalClasses: externalClasses,
        externalFunctions: externalFunctions,
        externalFunctionTypedef: externalFunctionTypedef);
  }
}
