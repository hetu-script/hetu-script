import 'dart:io';

import 'extern_class.dart';
import 'parser.dart';
import 'lexicon.dart';

typedef ReadFileMethod = dynamic Function(String filepath);
Future<String> defaultReadFileMethod(String filapath) async => await File(filapath).readAsString();
String readFileSync(String filapath) => File(filapath).readAsStringSync();

abstract class HT_Context {}

abstract class CodeRunner {
  String get curFileName;
  String get curDirectory;

  /// 注册外部命名空间，以访问外部类的构造函数和static成员
  /// 在脚本中需要存在对应的extern class声明
  void bindExternalClass(String id, HT_ExternClass namespace);

  dynamic eval(
    String content, {
    String fileName,
    String libName = HT_Lexicon.global,
    HT_Context context,
    ParseStyle style = ParseStyle.library,
    String invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });
}
