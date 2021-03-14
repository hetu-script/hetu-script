import 'lexicon.dart';
import 'token.dart';

/// 负责对原始文本进行词法分析并生成Token列表
class Lexer {
  Lexer();

  List<Token> lex(String content) {
    final tokens = <Token>[];
    var currentLine = 0;
    var column;
    var pattern = RegExp(
      HT_Lexicon.scriptPattern,
      caseSensitive: false,
      unicode: true,
    );
    for (final line in content.split('\n')) {
      ++currentLine;
      var matches = pattern.allMatches(line);
      for (final match in matches) {
        var matchString = match.group(0)!;
        column = match.start + 1;
        if (match.group(HT_Lexicon.tokenGroupComment) == null) {
          // 标识符
          if (match.group(HT_Lexicon.tokenGroupIdentifier) != null) {
            if (HT_Lexicon.keywords.contains(matchString)) {
              tokens.add(Token(matchString, currentLine, column));
            } else if (matchString == HT_Lexicon.TRUE) {
              tokens.add(TokenBoolLiteral(matchString, true, currentLine, column));
            } else if (matchString == HT_Lexicon.FALSE) {
              tokens.add(TokenBoolLiteral(matchString, false, currentLine, column));
            } else {
              tokens.add(TokenIdentifier(matchString, currentLine, column));
            }
          }
          // 标点符号和运算符号
          else if (match.group(HT_Lexicon.tokenGroupPunctuation) != null) {
            tokens.add(Token(matchString, currentLine, column));
          }
          // 数字字面量
          else if (match.group(HT_Lexicon.tokenGroupInt) != null) {
            tokens.add(TokenIntLiteral(matchString, int.parse(matchString), currentLine, column));
          } else if (match.group(HT_Lexicon.tokenGroupFloat) != null) {
            tokens.add(TokenFloatLiteral(matchString, double.parse(matchString), currentLine, column));
          }
          // 字符串字面量
          else if (match.group(HT_Lexicon.tokenGroupString) != null) {
            var literal = HT_Lexicon.convertStringLiteral(matchString);
            tokens.add(TokenStringLiteral(matchString, literal, currentLine, column));
          }
        }
      }
    }
    return tokens;
  }
}
