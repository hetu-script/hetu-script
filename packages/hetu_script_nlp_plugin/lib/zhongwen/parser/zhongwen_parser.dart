import 'package:hetu_script/parser.dart';

/// Default parser implementation used by Hetu.
class ZhongwenParser extends HTParser {
  static var anonymousFunctionIndex = 0;

  @override
  String get name => 'wenyan-lang';

  ZhongwenParser({required super.lexicon});

  @override
  void resetFlags() {}

  @override
  ASTNode parseExpr() {
    return ASTEmptyLine();
  }

  @override
  ASTNode? parseStmt({required ParseStyle style}) {
    return null;
  }
}
