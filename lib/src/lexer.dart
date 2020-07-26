import 'token.dart';
import 'common.dart';

/// 负责对原始文本进行词法分析并生成Token列表
class Lexer {
  List<Token> lex(String script) {
    var _tokens = <Token>[];
    var currentLine = 0;
    var column;
    for (var line in script.split('\n')) {
      ++currentLine;
      var matches = HS_Common.pattern.allMatches(line);
      for (var match in matches) {
        var matchString = match.group(0);
        column = match.start + 1;
        if (match.group(HS_Common.regCommentGrp) == null) {
          // 标识符
          if (match.group(HS_Common.regIdGrp) != null) {
            if (HS_Common.Keywords.contains(matchString)) {
              _tokens.add(Token(matchString, currentLine, column));
            } else if (matchString == HS_Common.True) {
              _tokens.add(TokenBoolLiteral(true, currentLine, column));
            } else if (matchString == HS_Common.False) {
              _tokens.add(TokenBoolLiteral(false, currentLine, column));
            } else {
              _tokens.add(TokenIdentifier(matchString, currentLine, column));
            }
          }
          // 标点符号和运算符号
          else if (match.group(HS_Common.regPuncGrp) != null) {
            _tokens.add(Token(matchString, currentLine, column));
          }
          // 数字字面量
          else if (match.group(HS_Common.regNumGrp) != null) {
            _tokens.add(TokenNumLiteral(num.parse(matchString), currentLine, column));
          }
          // 字符串字面量
          else if (match.group(HS_Common.regStrGrp) != null) {
            var literal = matchString.substring(1).substring(0, matchString.length - 2);

            literal = HS_Common.convertEscapeCode(literal);
            _tokens.add(TokenStringLiteral(literal, currentLine, column));
          }
        }
      }
    }
    return _tokens;
  }
}
