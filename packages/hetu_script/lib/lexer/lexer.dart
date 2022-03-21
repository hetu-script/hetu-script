import '../grammar/lexicon.dart';
// import '../error/error.dart';
import 'token.dart';
import '../shared/constants.dart' show CommentType;

/// Scans a string content and generates a list of Tokens.
class HTLexer {
  List<Token> lex(String content,
      {int line = 1, int column = 1, int start = 0}) {
    var curLine = line;
    var curColumn = column;
    final tokens = <Token>[];
    final pattern = RegExp(
      HTLexicon.tokenPattern,
      unicode: true,
    );
    var curOffset = start;
    final toksOfLine = <Token>[];

    void handleEndOfLine([int? offset]) {
      if (toksOfLine.isNotEmpty) {
        if (HTLexicon.autoSemicolonInsertAtStart
            .contains(toksOfLine.first.type)) {
          /// Add semicolon before a newline if the new line starting with '{, [, (, +, -' tokens
          /// and the last line does not ends with an unfinished token.
          if (tokens.isNotEmpty &&
              !HTLexicon.unfinishedTokens.contains(tokens.last.type)) {
            tokens.add(Token(HTLexicon.endOfStatementMark, curLine, 1,
                toksOfLine.first.offset + toksOfLine.first.length, 0));
          }
          tokens.addAll(toksOfLine);
        } else if (toksOfLine.last.type == HTLexicon.kReturn) {
          tokens.addAll(toksOfLine);
          tokens.add(Token(HTLexicon.endOfStatementMark, curLine, curColumn + 1,
              toksOfLine.last.offset + toksOfLine.last.length, 0));
        } else {
          tokens.addAll(toksOfLine);
        }
      } else {
        tokens.add(TokenEmptyLine(curLine, curColumn, start));
      }
      ++curLine;
      // empty line counts as a character
      if (offset != null) {
        curOffset = offset + 1;
      } else {
        curOffset += 1;
      }
      toksOfLine.clear();
    }

    final matches = pattern.allMatches(content);
    for (final match in matches) {
      final matchString = match.group(0)!;
      curColumn = column + match.start;
      if (match.group(HTLexicon.tokenGroupSingleComment) != null) {
        if (toksOfLine.isEmpty) {
          toksOfLine.add(TokenComment(matchString, curLine, curColumn,
              curOffset + match.start, curOffset + match.end,
              commentType:
                  matchString.startsWith(HTLexicon.documentationCommentPattern)
                      ? CommentType.documentation
                      : CommentType.singleLine));
        } else {
          toksOfLine.add(TokenComment(matchString, curLine, curColumn,
              curOffset + match.start, curOffset + match.end,
              commentType: CommentType.singleLine, isTrailing: true));
        }
      } else if (match.group(HTLexicon.tokenGroupBlockComment) != null) {
        if (toksOfLine.isEmpty) {
          toksOfLine.add(TokenComment(matchString, curLine, curColumn,
              curOffset + match.start, curOffset + match.end,
              commentType: CommentType.multiLine));
        } else {
          toksOfLine.add(TokenComment(matchString, curLine, curColumn,
              curOffset + match.start, curOffset + match.end,
              commentType: CommentType.multiLine, isTrailing: true));
        }
      } else if (match.group(HTLexicon.tokenGroupIdentifier) != null) {
        if (matchString == HTLexicon.kTrue) {
          toksOfLine.add(TokenBooleanLiteral(matchString, true, curLine,
              curColumn, curOffset + match.start, curOffset + match.end));
        } else if (matchString == HTLexicon.kFalse) {
          toksOfLine.add(TokenBooleanLiteral(matchString, false, curLine,
              curColumn, curOffset + match.start, curOffset + match.end));
        } else if (HTLexicon.keywords.contains(matchString)) {
          toksOfLine.add(Token(matchString, curLine, curColumn,
              curOffset + match.start, curOffset + match.end,
              isKeyword: true));
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
      } else if (match.group(HTLexicon.tokenGroupApostropheString) != null) {
        final literal = matchString.substring(1, matchString.length - 1);
        toksOfLine.add(TokenStringLiteral(
            literal,
            HTLexicon.stringStart1,
            HTLexicon.stringEnd1,
            curLine,
            curColumn,
            curOffset + match.start,
            curOffset + match.end));
      } else if (match.group(HTLexicon.tokenGroupQuotationString) != null) {
        final literal = matchString.substring(1, matchString.length - 1);
        toksOfLine.add(TokenStringLiteral(
            literal,
            HTLexicon.stringStart2,
            HTLexicon.stringEnd2,
            curLine,
            curColumn,
            curOffset + match.start,
            curOffset + match.end));
      } else if (match.group(HTLexicon.tokenGroupStringGraveAccent) != null) {
        final literal = matchString.substring(1, matchString.length - 1);
        toksOfLine.add(TokenIdentifier(literal, curLine, curColumn,
            curOffset + match.start, curOffset + match.end));
      } else if (match
              .group(HTLexicon.tokenGroupApostropheStringInterpolation) !=
          null) {
        final token = _hanldeStringInterpolation(
            matchString,
            HTLexicon.stringStart1,
            HTLexicon.stringEnd1,
            curLine,
            curColumn + HTLexicon.stringStart1.length,
            curOffset + match.start);
        toksOfLine.add(token);
      } else if (match
              .group(HTLexicon.tokenGroupQuotationStringInterpolation) !=
          null) {
        final token = _hanldeStringInterpolation(
            matchString,
            HTLexicon.stringStart2,
            HTLexicon.stringEnd2,
            curLine,
            curColumn + HTLexicon.stringStart2.length,
            curOffset + match.start);
        toksOfLine.add(token);
      } else if (match.group(HTLexicon.tokenGroupNewline) != null) {
        handleEndOfLine(match.end);
      }
    }

    if (toksOfLine.isNotEmpty) {
      handleEndOfLine(toksOfLine.last.end);
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
          column: column +
              match.start +
              HTLexicon.stringInterpolationMark.length +
              HTLexicon.stringInterpolationStart.length,
          start: start + quotationLeft.length + match.start);
      if (tokens.isNotEmpty) {
        interpolations.add(tokens);
      } else {
        interpolations.add([
          TokenEmpty(
              line,
              // move beyond '${'
              column +
                  match.start +
                  HTLexicon.stringInterpolationMark.length +
                  HTLexicon.stringInterpolationStart.length,
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
