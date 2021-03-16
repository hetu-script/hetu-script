import 'lexicon.dart';
import 'token.dart';

/// 负责对原始文本进行词法分析并生成Token列表
class Lexer {
  Lexer();

  List<Token> lex(String content, String fileName) {
    final tokens = <Token>[];
    var curLine = 0;
    var curColumn;
    var pattern = RegExp(
      HTLexicon.scriptPattern,
      caseSensitive: false,
      unicode: true,
    );
    for (final line in content.split('\n')) {
      ++curLine;
      var matches = pattern.allMatches(line);
      for (final match in matches) {
        var matchString = match.group(0)!;
        curColumn = match.start + 1;
        if (match.group(HTLexicon.tokenGroupComment) == null) {
          // 标识符
          if (match.group(HTLexicon.tokenGroupIdentifier) != null) {
            if (HTLexicon.keywords.contains(matchString)) {
              tokens.add(Token(matchString, fileName, curLine, curColumn));
            } else if (matchString == HTLexicon.TRUE) {
              tokens.add(TokenBoolLiteral(matchString, true, fileName, curLine, curColumn));
            } else if (matchString == HTLexicon.FALSE) {
              tokens.add(TokenBoolLiteral(matchString, false, fileName, curLine, curColumn));
            } else {
              tokens.add(TokenIdentifier(matchString, fileName, curLine, curColumn));
            }
          }
          // 标点符号和运算符号
          else if (match.group(HTLexicon.tokenGroupPunctuation) != null) {
            tokens.add(Token(matchString, fileName, curLine, curColumn));
          }
          // 数字字面量
          else if (match.group(HTLexicon.tokenGroupNumber) != null) {
            if (matchString.contains(HTLexicon.memberGet)) {
              tokens.add(TokenFloatLiteral(matchString, double.parse(matchString), fileName, curLine, curColumn));
            } else {
              tokens.add(TokenIntLiteral(matchString, int.parse(matchString), fileName, curLine, curColumn));
            }
          }
          // 字符串字面量
          else if (match.group(HTLexicon.tokenGroupString) != null) {
            var literal = HTLexicon.convertStringLiteral(matchString);
            tokens.add(TokenStringLiteral(matchString, literal, fileName, curLine, curColumn));
          }
        }
      }
    }
    return tokens;
  }
}
