import 'lexicon.dart';
import 'token.dart';

/// 负责对原始文本进行词法分析并生成Token列表
class Lexer {
  Lexer();

  List<Token> lex(String content, String fileName) {
    final tokens = <Token>[];
    var curLine = 0;
    var curColumn;
    final pattern = RegExp(
      HTLexicon.scriptPattern,
      caseSensitive: false,
      unicode: true,
    );
    for (final line in content.split('\n')) {
      ++curLine;
      final matches = pattern.allMatches(line);
      final toksOfLine = <Token>[];
      for (final match in matches) {
        final matchString = match.group(0)!;
        curColumn = match.start + 1;
        if (match.group(HTLexicon.tokenGroupComment) == null) {
          // 标识符
          if (match.group(HTLexicon.tokenGroupIdentifier) != null) {
            if (HTLexicon.reservedKeywords.contains(matchString)) {
              toksOfLine.add(Token(matchString, fileName, curLine, curColumn));
            } else if (matchString == HTLexicon.TRUE) {
              toksOfLine.add(TokenBoolLiteral(matchString, true, fileName, curLine, curColumn));
            } else if (matchString == HTLexicon.FALSE) {
              toksOfLine.add(TokenBoolLiteral(matchString, false, fileName, curLine, curColumn));
            } else {
              toksOfLine.add(TokenIdentifier(matchString, fileName, curLine, curColumn));
            }
          }
          // 标点符号和运算符号
          else if (match.group(HTLexicon.tokenGroupPunctuation) != null) {
            toksOfLine.add(Token(matchString, fileName, curLine, curColumn));
          }
          // 数字字面量
          else if (match.group(HTLexicon.tokenGroupNumber) != null) {
            if (matchString.contains(HTLexicon.memberGet)) {
              toksOfLine.add(TokenFloatLiteral(matchString, double.parse(matchString), fileName, curLine, curColumn));
            } else {
              toksOfLine.add(TokenIntLiteral(matchString, int.parse(matchString), fileName, curLine, curColumn));
            }
          }
          // 字符串字面量
          else if (match.group(HTLexicon.tokenGroupString) != null) {
            var literal = HTLexicon.convertStringLiteral(matchString);
            toksOfLine.add(TokenStringLiteral(matchString, literal, fileName, curLine, curColumn));
          }
        }
      }

      if (toksOfLine.isNotEmpty) {
        if (HTLexicon.ASIStart.contains(toksOfLine.first.type)) {
          /// According to Javascript standard, add semicolon before a newline
          /// if the new line starting with '[, (, +, -, /' tokens
          tokens.add(Token(HTLexicon.semicolon, fileName, curLine, 1));
          tokens.addAll(toksOfLine);
        } else if (HTLexicon.ASIEnding.contains(toksOfLine.last)) {
          tokens.addAll(toksOfLine);
          tokens.add(Token(HTLexicon.semicolon, fileName, curLine, curColumn + 1));
        } else {
          tokens.addAll(toksOfLine);
        }
      }
    }

    return tokens;
  }
}
