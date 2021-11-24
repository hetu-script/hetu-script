import '../grammar/lexicon.dart';
// import '../error/error.dart';
import 'token.dart';

/// Scans a string content and generates a list of Tokens.
class HTLexer {
  List<Token> lex(String content,
      {int line = 1, int column = 0, int start = 0}) {
    var curLine = line;
    var curColumn = column;
    final tokens = <Token>[];
    final pattern = RegExp(
      HTLexicon.tokenPattern,
      unicode: true,
    );
    var curOffset = start;
    for (final line in content.split('\n')) {
      final matches = pattern.allMatches(line);
      final toksOfLine = <Token>[];
      for (final match in matches) {
        final matchString = match.group(0)!;
        curColumn = column + match.start + 1;
        if (match.group(HTLexicon.tokenGroupSingleComment) != null) {
          toksOfLine.add(TokenSingleLineComment(matchString, curLine, curColumn,
              curOffset + match.start, curOffset + match.end));
        } else if (match.group(HTLexicon.tokenGroupBlockComment) != null) {
          toksOfLine.add(TokenMultiLineComment(matchString, curLine, curColumn,
              curOffset + match.start, curOffset + match.end));
        } else if (match.group(HTLexicon.tokenGroupIdentifier) != null) {
          if (matchString == HTLexicon.TRUE) {
            toksOfLine.add(TokenBooleanLiteral(matchString, true, curLine,
                curColumn, curOffset + match.start, curOffset + match.end));
          } else if (matchString == HTLexicon.FALSE) {
            toksOfLine.add(TokenBooleanLiteral(matchString, false, curLine,
                curColumn, curOffset + match.start, curOffset + match.end));
          } else if (HTLexicon.keywords.contains(matchString)) {
            toksOfLine.add(Token(matchString, curLine, curColumn,
                curOffset + match.start, curOffset + match.end, true));
          } else {
            toksOfLine.add(TokenIdentifier(matchString, curLine, curColumn,
                curOffset + match.start, curOffset + match.end));
          }
        } else if (match.group(HTLexicon.tokenGroupPunctuation) != null) {
          toksOfLine.add(Token(matchString, curLine, curColumn,
              curOffset + match.start, curOffset + match.end));
        } else if (match.group(HTLexicon.tokenGroupNumber) != null) {
          if (matchString.contains(HTLexicon.decimalPoint)) {
            toksOfLine.add(TokenFloatLiteral(
                matchString,
                double.parse(matchString),
                curLine,
                curColumn,
                curOffset + match.start,
                curOffset + match.end));
          } else {
            toksOfLine.add(TokenIntLiteral(
                matchString,
                int.parse(matchString),
                curLine,
                curColumn,
                curOffset + match.start,
                curOffset + match.end));
          }
        } else if (match.group(HTLexicon.tokenGroupStringSingleQuotation) !=
            null) {
          final literal = matchString.substring(1, matchString.length - 1);
          toksOfLine.add(TokenStringLiteral(
              literal,
              HTLexicon.singleQuotationLeft,
              HTLexicon.singleQuotationRight,
              curLine,
              curColumn,
              curOffset + match.start,
              curOffset + match.end));
        } else if (match.group(HTLexicon.tokenGroupStringDoubleQuotation) !=
            null) {
          final literal = matchString.substring(1, matchString.length - 1);
          toksOfLine.add(TokenStringLiteral(
              literal,
              HTLexicon.doubleQuotationLeft,
              HTLexicon.doubleQuotationRight,
              curLine,
              curColumn,
              curOffset + match.start,
              curOffset + match.end));
        } else if (match
                .group(HTLexicon.tokenGroupStringInterpolationSingleMark) !=
            null) {
          final token = _hanldeStringInterpolation(
              matchString,
              HTLexicon.singleQuotationLeft,
              HTLexicon.singleQuotationRight,
              curLine,
              curColumn + HTLexicon.singleQuotationLeft.length,
              curOffset + match.start);
          toksOfLine.add(token);
        } else if (match
                .group(HTLexicon.tokenGroupStringInterpolationDoubleMark) !=
            null) {
          final token = _hanldeStringInterpolation(
              matchString,
              HTLexicon.doubleQuotationLeft,
              HTLexicon.doubleQuotationRight,
              curLine,
              curColumn + HTLexicon.doubleQuotationLeft.length,
              curOffset + match.start);
          toksOfLine.add(token);
        }
      }

      if (toksOfLine.isNotEmpty) {
        if (HTLexicon.ASIStart.contains(toksOfLine.first.type)) {
          /// Add semicolon before a newline if the new line starting with '{, [, (, +, -' tokens
          /// and the last line does not ends with an unfinished token.
          if (tokens.isNotEmpty &&
              !HTLexicon.unfinishedTokens.contains(tokens.last.type)) {
            tokens.add(Token(HTLexicon.semicolon, curLine, 1,
                toksOfLine.first.offset + toksOfLine.first.length, 0));
          }
          tokens.addAll(toksOfLine);
        } else if (toksOfLine.last.type == HTLexicon.RETURN) {
          tokens.addAll(toksOfLine);
          tokens.add(Token(HTLexicon.semicolon, curLine, curColumn + 1,
              toksOfLine.last.offset + toksOfLine.last.length, 0));
        } else {
          tokens.addAll(toksOfLine);
        }
      }

      // else {
      //   if (tokens.isNotEmpty) {
      //     tokens.add(TokenEmptyLine(
      //         curLine, curColumn, tokens.last.offset + tokens.last.length));
      //   } else {
      //     tokens.add(TokenEmptyLine(curLine, curColumn, 0));
      //   }
      // }
      ++curLine;
      // empty line counts as a character
      curOffset += line.length + 1;
    }
    if (tokens.isEmpty) {
      tokens.add(TokenEmptyLine(curLine, curColumn, start));
    }
    return tokens;
  }

  // String _escapeString(String literal) {
  //   HTLexicon.stringReplaces.forEach((key, value) {
  //     literal = literal.replaceAll(key, value);
  //   });
  //   return literal;
  // }

  Token _hanldeStringInterpolation(String matchString, String quotationLeft,
      String quotationRight, int line, int column, int start) {
    final interpolations = <List<Token>>[];
    final literal = matchString.substring(1, matchString.length - 1);
    final pattern = RegExp(HTLexicon.stringInterpolationPattern);
    final matches = pattern.allMatches(literal);
    for (final match in matches) {
      final innerString = match.group(1);
      // do not throw here, handle in analyzer instead
      // if (matchString == null) {
      //   throw HTError.emptyString();
      // }
      final tokens = lex(innerString ?? '',
          line: line,
          column:
              column + match.start + HTLexicon.stringInterpolationStart.length,
          start: start + quotationLeft.length + match.start);
      if (tokens.isNotEmpty) {
        interpolations.add(tokens);
      } else {
        interpolations.add([
          TokenEmpty(
              line,
              // move beyond '${'
              column + match.start + HTLexicon.stringInterpolationStart.length,
              start +
                  quotationLeft.length +
                  match.start +
                  HTLexicon.stringInterpolationEnd.length)
        ]);
      }
    }
    return TokenStringInterpolation(literal, quotationLeft, quotationRight,
        interpolations, line, column, start, matchString.length);
  }
}
