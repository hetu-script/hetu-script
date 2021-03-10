import 'lexicon.dart';

abstract class HT_Grammar {
  // import语句
  static const importStmt = [HT_Lexicon.IMPORT];

  // 动态类型变量
  static const varDeclStmt = [HT_Lexicon.VAR];

  // 静态类型变量
  static const letDeclStmt = [HT_Lexicon.LET];

  // 常量
  static const constDeclStmt = [HT_Lexicon.CONST];

  // 类
  static const classDeclStmt = [HT_Lexicon.CLASS];

  // 函数
  static const funcDeclStmt = [HT_Lexicon.FUN];
}
