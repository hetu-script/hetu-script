import 'extern_class.dart';
import 'parser.dart';
import 'lexicon.dart';
import 'context.dart';

mixin InterpreterRef {
  late final Interpreter interpreter;
}

abstract class Interpreter {
  int curLine = 0;
  int curColumn = 0;
  String curFileName = '';

  String get workingDirectory;

  /// 注册外部命名空间，以访问外部类的构造函数和static成员
  /// 在脚本中需要存在对应的extern class声明
  void bindExternalNamespace(String id, HT_ExternClass namespace);
  HT_ExternClass fetchExternalClass(String id);
  void bindExternalFunction(String id, Function function);
  Function fetchExternalFunction(String id);

  void bindExternalVariable(String id, Function getter, Function setter);
  dynamic getExternalVariable(String id);
  void setExternalVariable(String id, value);

  dynamic eval(
    String content, {
    String? fileName,
    String libName = HT_Lexicon.global,
    HT_Context? context,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  dynamic evalf(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  dynamic evalfSync(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}});
}
