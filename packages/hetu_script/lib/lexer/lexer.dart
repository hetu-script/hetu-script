import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
// import '../error/error.dart';
import 'token.dart';

const Set<String> _unfinishedTokens = {
  HTLexicon.logicalNot,
  HTLexicon.multiply,
  HTLexicon.devide,
  HTLexicon.modulo,
  HTLexicon.add,
  HTLexicon.subtract,
  HTLexicon.lesser, // chevronsLeft,
  HTLexicon.lesserOrEqual,
  HTLexicon.greater,
  HTLexicon.greaterOrEqual,
  HTLexicon.equal,
  HTLexicon.notEqual,
  HTLexicon.ifNull,
  HTLexicon.logicalAnd,
  HTLexicon.logicalOr,
  HTLexicon.assign,
  HTLexicon.assignAdd,
  HTLexicon.assignSubtract,
  HTLexicon.assignMultiply,
  HTLexicon.assignDevide,
  HTLexicon.assignIfNull,
  HTLexicon.memberGet,
  HTLexicon.parenthesesLeft,
  HTLexicon.bracesLeft,
  HTLexicon.bracketsLeft,
  HTLexicon.comma,
  HTLexicon.colon,
  HTLexicon.singleArrow,
  HTLexicon.doubleArrow,
  Semantic.singleLineComment,
  Semantic.multiLineComment,
  Semantic.consumingLineEndComment,
};

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
    final matches = pattern.allMatches(content);
    final toksOfLine = <Token>[];

    void handleEndOfLine([int? offset]) {
      if (toksOfLine.isNotEmpty) {
        if (HTLexicon.defaultSemicolonStart.contains(toksOfLine.first.type)) {
          /// Add semicolon before a newline if the new line starting with '{, [, (, +, -' tokens
          /// and the last line does not ends with an unfinished token.
          if (tokens.isNotEmpty &&
              !_unfinishedTokens.contains(tokens.last.type)) {
            tokens.add(Token(HTLexicon.semicolon, curLine, 1,
                toksOfLine.first.offset + toksOfLine.first.length, 0));
          }
          tokens.addAll(toksOfLine);
        } else if (toksOfLine.last.type == HTLexicon.kReturn) {
          tokens.addAll(toksOfLine);
          tokens.add(Token(HTLexicon.semicolon, curLine, curColumn + 1,
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

    for (final match in matches) {
      final matchString = match.group(0)!;
      curColumn = column + match.start + 1;
      if (match.group(HTLexicon.tokenGroupSingleComment) != null) {
        if (toksOfLine.isEmpty) {
          toksOfLine.add(TokenSingleLineComment(matchString, curLine, curColumn,
              curOffset + match.start, curOffset + match.end));
        } else {
          toksOfLine.add(TokenConsumingLineEndComment(matchString, curLine,
              curColumn, curOffset + match.start, curOffset + match.end));
        }
      } else if (match.group(HTLexicon.tokenGroupBlockComment) != null) {
        toksOfLine.add(TokenMultiLineComment(matchString, curLine, curColumn,
            curOffset + match.start, curOffset + match.end));
      } else if (match.group(HTLexicon.tokenGroupIdentifier) != null) {
        if (matchString == HTLexicon.kTrue) {
          toksOfLine.add(TokenBooleanLiteral(matchString, true, curLine,
              curColumn, curOffset + match.start, curOffset + match.end));
        } else if (matchString == HTLexicon.kFalse) {
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
      } else if (match.group(HTLexicon.tokenGroupApostropheString) != null) {
        final literal = matchString.substring(1, matchString.length - 1);
        toksOfLine.add(TokenStringLiteral(
            literal,
            HTLexicon.apostropheLeft,
            HTLexicon.apostropheRight,
            curLine,
            curColumn,
            curOffset + match.start,
            curOffset + match.end));
      } else if (match.group(HTLexicon.tokenGroupQuotationString) != null) {
        final literal = matchString.substring(1, matchString.length - 1);
        toksOfLine.add(TokenStringLiteral(
            literal,
            HTLexicon.quotationLeft,
            HTLexicon.quotationRight,
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
            HTLexicon.apostropheLeft,
            HTLexicon.apostropheRight,
            curLine,
            curColumn + HTLexicon.apostropheLeft.length,
            curOffset + match.start);
        toksOfLine.add(token);
      } else if (match
              .group(HTLexicon.tokenGroupQuotationStringInterpolation) !=
          null) {
        final token = _hanldeStringInterpolation(
            matchString,
            HTLexicon.quotationLeft,
            HTLexicon.quotationRight,
            curLine,
            curColumn + HTLexicon.quotationLeft.length,
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
