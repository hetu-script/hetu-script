import 'lexicon.dart';

abstract class HTGrammar {
  // import语句
  static const importStmt = [HTLexicon.IMPORT];

  // 动态类型变量
  static const varDeclStmt = [HTLexicon.VAR];

  // 静态类型变量
  static const letDeclStmt = [HTLexicon.LET];

  // 常量
  static const constDeclStmt = [HTLexicon.CONST];

  // 类
  static const classDeclStmt = [HTLexicon.CLASS];

  // 函数
  static const funcDeclStmt = [HTLexicon.FUN];
}
