import 'lexicon.dart';
import 'token.dart';

/// 负责对原始文本进行词法分析并生成Token列表
class Lexer {
  static const _stringReplaces = <String, String>{
    '\\\\': '\\',
    '\\n': '\n',
    '\\\'': '\'',
  };

  static String _convertStringLiteral(String literal) {
    var result = literal.substring(1).substring(0, literal.length - 2);
    for (final key in _stringReplaces.keys) {
      result = result.replaceAll(key, _stringReplaces[key]);
    }
    return result;
  }

  List<Token> lex(String script) //, {HT_Lexicon HT_Lexicon = const HT_Lexicon()})
  {
    var _tokens = <Token>[];
    var currentLine = 0;
    var column;
    var pattern = RegExp(
      HT_Lexicon.scriptPattern,
      caseSensitive: false,
      unicode: true,
    );
    for (final line in script.split('\n')) {
      ++currentLine;
      var matches = pattern.allMatches(line);
      for (final match in matches) {
        var matchString = match.group(0);
        column = match.start + 1;
        if (match.group(HT_Lexicon.tokenGroupComment) == null) {
          // 标识符
          if (match.group(HT_Lexicon.tokenGroupIdentifier) != null) {
            if (HT_Lexicon.keywords.contains(matchString)) {
              _tokens.add(Token(matchString, currentLine, column));
            } else if (matchString == HT_Lexicon.TRUE) {
              _tokens.add(TokenBoolLiteral(matchString, true, currentLine, column));
            } else if (matchString == HT_Lexicon.FALSE) {
              _tokens.add(TokenBoolLiteral(matchString, false, currentLine, column));
            } else {
              _tokens.add(TokenIdentifier(matchString, currentLine, column));
            }
          }
          // 标点符号和运算符号
          else if (match.group(HT_Lexicon.tokenGroupPunctuation) != null) {
            _tokens.add(Token(matchString, currentLine, column));
          }
          // 数字字面量
          else if (match.group(HT_Lexicon.tokenGroupNumber) != null) {
            _tokens.add(TokenNumLiteral(matchString, num.parse(matchString), currentLine, column));
          }
          // 字符串字面量
          else if (match.group(HT_Lexicon.tokenGroupString) != null) {
            var literal = _convertStringLiteral(matchString);
            _tokens.add(TokenStringLiteral(matchString, literal, currentLine, column));
          }
        }
      }
    }
    return _tokens;
  }
}
