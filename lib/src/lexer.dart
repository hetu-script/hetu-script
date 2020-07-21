import 'token.dart';
import 'common.dart';

/// 负责对原始文本进行词法分析并生成Token列表
class Lexer {
  List<Token> lex(String script, {bool commandLine = false}) {
    var _tokens = <Token>[];
    var currentLine = 0;
    var column = 0;
    for (var line in script.split('\n')) {
      ++currentLine;
      if (commandLine) {
        var matches = HS_Common.patterns[HS_Common.commandLine].allMatches(line);
        var currentWord = matches.first.group(0);
        _tokens.add(TokenIdentifier(currentWord, currentLine, column));

        for (var i = 1; i < matches.length; ++i) {
          column += currentWord.length;
          currentWord = matches.elementAt(i).group(0);
          _tokens.add(TokenStringLiteral(currentWord, currentLine, column));
        }
      } else {
        var matches = HS_Common.pattern.allMatches(line);
        for (var match in matches) {
          var matchString = match.group(0);
          column = match.start;
          if (match.group(HS_Common.regCommentGrp) == null) {
            // 标识符
            if (match.group(HS_Common.regIdGrp) != null) {
              if (HS_Common.Keywords.contains(matchString)) {
                _tokens.add(Token(matchString, currentLine, column));
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

              for (var key in HS_Common.stringReplaces.keys) {
                literal = literal.replaceAll(key, HS_Common.stringReplaces[key]);
              }
              _tokens.add(TokenStringLiteral(literal, currentLine, column));
            }
          }
        }
      }
    }
    return _tokens;
  }
}
