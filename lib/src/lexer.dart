import 'lexicon.dart';
import 'token.dart';

/// 负责对原始文本进行词法分析并生成Token列表
class Lexer {
  static const stringReplaces = <String, String>{
    r'\\': '\\',
    r'\n': '\n',
    r"\'": '\'',
  };

  Lexer();

  List<Token> lex(String content, String fileName,
      {int line = 0, int column = 0}) {
    var curLine = line;
    var curColumn = 0;
    final tokens = <Token>[];
    final pattern = RegExp(
      HTLexicon.scriptPattern,
      unicode: true,
    );
    for (final line in content.split('\n')) {
      ++curLine;
      final matches = pattern.allMatches(line);
      final toksOfLine = <Token>[];
      for (final match in matches) {
        final matchString = match.group(0)!;
        curColumn = column + match.start + 1;
        if (match.group(HTLexicon.tokenGroupComment) == null) {
          // 标识符
          if (match.group(HTLexicon.tokenGroupIdentifier) != null) {
            if (HTLexicon.reservedKeywords.contains(matchString)) {
              toksOfLine.add(Token(matchString, fileName, curLine, curColumn));
            } else if (matchString == HTLexicon.TRUE) {
              toksOfLine.add(TokenBoolLiteral(
                  matchString, true, fileName, curLine, curColumn));
            } else if (matchString == HTLexicon.FALSE) {
              toksOfLine.add(TokenBoolLiteral(
                  matchString, false, fileName, curLine, curColumn));
            } else {
              toksOfLine.add(
                  TokenIdentifier(matchString, fileName, curLine, curColumn));
            }
          }
          // 标点符号和运算符号
          else if (match.group(HTLexicon.tokenGroupPunctuation) != null) {
            toksOfLine.add(Token(matchString, fileName, curLine, curColumn));
          }
          // 数字字面量
          else if (match.group(HTLexicon.tokenGroupNumber) != null) {
            if (matchString.contains(HTLexicon.memberGet)) {
              toksOfLine.add(TokenFloatLiteral(matchString,
                  double.parse(matchString), fileName, curLine, curColumn));
            } else {
              toksOfLine.add(TokenIntLiteral(matchString,
                  int.parse(matchString), fileName, curLine, curColumn));
            }
          }
          // 字符串字面量
          else if (match.group(HTLexicon.tokenGroupString) != null) {
            final stringTokens = <Token>[];

            final literal = matchString.substring(1, matchString.length - 1);

            final pattern = RegExp(r'(\${([^}]+)})');
            final matches = pattern.allMatches(literal);
            var start = 0;
            if (matches.isNotEmpty) {
              for (final match in matches) {
                if (match.group(1) != null) {
                  if (match.start > 0) {
                    final preString = literal.substring(start, match.start);
                    final processed = escapeString(preString);
                    stringTokens.add(TokenStringLiteral(
                        processed, fileName, curLine, curColumn));
                    stringTokens.add(
                        Token(HTLexicon.add, fileName, curLine, curColumn + 1));
                  }
                  start += match.end - start;

                  final matchString = match.group(1)!;
                  final expresstion =
                      matchString.substring(2, matchString.length - 1);
                  stringTokens.add(TokenIdentifier(
                      HTLexicon.string, fileName, curLine, curColumn));
                  stringTokens.add(Token(
                      HTLexicon.memberGet, fileName, curLine, match.start));
                  stringTokens.add(TokenIdentifier(
                      HTLexicon.parse, fileName, curLine, curColumn));
                  stringTokens.add(Token(
                      HTLexicon.roundLeft, fileName, curLine, match.start));
                  stringTokens.addAll(lex(expresstion, fileName,
                      line: curLine, column: match.start));
                  stringTokens.add(Token(
                      HTLexicon.roundRight, fileName, curLine, match.end));
                  stringTokens
                      .add(Token(HTLexicon.add, fileName, curLine, match.end));
                }
              }
              if (start < literal.length) {
                final restString = literal.substring(start);
                final processed = escapeString(restString);
                stringTokens.add(TokenStringLiteral(
                    processed, fileName, curLine, curColumn));
              } else {
                stringTokens.removeLast();
              }
            } else {
              final processed = escapeString(literal);
              stringTokens.add(
                  TokenStringLiteral(processed, fileName, curLine, curColumn));
            }

            toksOfLine.addAll(stringTokens);
          }
        }
      }

      if (toksOfLine.isNotEmpty) {
        if (HTLexicon.ASIStart.contains(toksOfLine.first.type)) {
          /// Add semicolon before a newline if the new line starting with '[, (, +, -' tokens
          /// and the last line does not ends with an unfinished token.
          if (tokens.isNotEmpty &&
              !HTLexicon.unfinishedTokens.contains(tokens.last.type)) {
            tokens.add(Token(HTLexicon.semicolon, fileName, curLine, 1));
          }
          tokens.addAll(toksOfLine);
        } else if (toksOfLine.last.type == HTLexicon.RETURN) {
          tokens.addAll(toksOfLine);
          tokens.add(
              Token(HTLexicon.semicolon, fileName, curLine, curColumn + 1));
        } else {
          tokens.addAll(toksOfLine);
        }
      }
    }

    return tokens;
  }

  String escapeString(String literal) {
    stringReplaces.forEach((key, value) {
      literal = literal.replaceAll(key, value);
    });
    return literal;
  }
}
