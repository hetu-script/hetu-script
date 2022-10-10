// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import '../utils/pair.dart';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/analyzer.dart';
import 'package:hetu_script/parser.dart' show Token;

import '../protocol/protocol_generated.dart';
import '../protocol/protocol_special.dart';
import '../protocol/protocol_common.dart' as client;
// import 'protocol/protocol_server.dart' as server;
import 'mapping.dart';
// import 'package:analysis_server/src/protocol_server.dart' as server show SourceEdit;
// import 'package:analyzer/dart/analysis/features.dart';
// import 'package:analyzer/dart/analysis/results.dart';
// import 'package:analyzer/dart/ast/token.dart';
// import 'package:analyzer/source/line_info.dart';
// import 'package:analyzer/src/dart/scanner/reader.dart';
// import 'package:analyzer/src/dart/scanner/scanner.dart';
// import 'package:analyzer/src/generated/source.dart';
// import 'package:analyzer_plugin/utilities/pair.dart';
// import 'package:dart_style/dart_style.dart';

// final parser = HTAstParser();
// final formatter = HTFormatter();

/// Transforms a sequence of LSP document change events to a sequence of source
/// edits used by analysis plugins.
///
/// Since the translation from line/characters to offsets needs to take previous
/// changes into account, this will also apply the edits to [oldContent].
ErrorOr<Pair<String, List<client.SourceEdit>>> applyAndConvertEditsToServer(
  String oldContent,
  List<
          Either2<TextDocumentContentChangeEvent1,
              TextDocumentContentChangeEvent2>>
      changes, {
  failureIsCritical = false,
}) {
  var newContent = oldContent;
  final serverEdits = <client.SourceEdit>[];

  for (var change in changes) {
    // Change is a union that may/may not include a range. If no range
    // is provided (t2 of the union) the whole document should be replaced.
    final result = change.map(
      // TextDocumentContentChangeEvent1
      // {range, text}
      (change) {
        final lines = LineInfo.fromContent(newContent);
        final offsetStart = toOffset(lines, change.range.start,
            failureIsCritial: failureIsCritical);
        final offsetEnd = toOffset(lines, change.range.end,
            failureIsCritial: failureIsCritical);
        if (offsetStart.isError) {
          return ErrorOr.error(offsetStart.error);
        }
        if (offsetEnd.isError) {
          return ErrorOr.error(offsetEnd.error);
        }
        newContent = newContent.replaceRange(
            offsetStart.result, offsetEnd.result, change.text);
        serverEdits.add(client.SourceEdit(offsetStart.result,
            offsetEnd.result - offsetStart.result, change.text));
      },
      // TextDocumentContentChangeEvent2
      // {text}
      (change) {
        serverEdits
          ..clear()
          ..add(client.SourceEdit(0, newContent.length, change.text));
        newContent = change.text;
      },
    );
    // If any change fails, immediately return the error.
    if (result?.isError ?? false) {
      return ErrorOr.error(result.error);
    }
  }
  return ErrorOr.success(Pair(newContent, serverEdits));
}

ErrorOr<List<TextEdit>> generateEditsForFormatting(
  String unformatted,
  int pageWidth, {
  Range range,
}) {
  try {
    final formatted = HTFormatter().formatString(unformatted,
        config: FormatterConfig(pageWidth: pageWidth));
    if (formatted == unformatted) {
      return success();
    }
    return _generateMinimalEdits(unformatted, formatted, range: range);
  } catch (e) {
    // If the document fails to parse, just return no edits to avoid the the
    // use seeing edits on every save with invalid code (if LSP gains the
    // ability to pass a context to know if the format was manually invoked
    // we may wish to change this to return an error for that case).
    return success();
  }
}

List<TextEdit> _generateFullEdit(
    LineInfo lineInfo, String unformatted, String formatted) {
  final end = lineInfo.getLocation(unformatted.length);
  return [
    TextEdit(
      range:
          Range(start: Position(line: 0, character: 0), end: toPosition(end)),
      newText: formatted,
    )
  ];
}

/// Generates edits that modify the minimum amount of code (only whitespace) to
/// change [unformatted] to [formatted].
///
/// This allows editors to more easily track important locations (such as
/// breakpoints) without needing to do their own diffing.
///
/// If [range] is supplied, only whitespace edits that fall entirely inside this
/// range will be included in the results.
ErrorOr<List<TextEdit>> _generateMinimalEdits(
  String unformatted,
  String formatted, {
  Range range,
}) {
  final lineInfo = LineInfo.fromContent(unformatted);
  final rangeStart = range != null ? toOffset(lineInfo, range.start) : null;
  final rangeEnd = range != null ? toOffset(lineInfo, range.end) : null;

  if (rangeStart?.isError ?? false) {
    return failure(rangeStart);
  }
  if (rangeEnd?.isError ?? false) {
    return failure(rangeEnd);
  }

  final lexer = HTDefaultLexer();

  // It shouldn't be the case that we can't parse the code but if it happens
  // fall back to a full replacement rather than fail.
  final parsedFormatted = lexer.lex(unformatted);
  final parsedUnformatted = lexer.lex(formatted);
  // if (parsedFormatted == null || parsedUnformatted == null) {
  //   return success(_generateFullEdit(lineInfo, unformatted, formatted));
  // }

  final unformattedTokens = _iterateAllTokens(parsedUnformatted).iterator;
  final formattedTokens = _iterateAllTokens(parsedFormatted).iterator;

  // final unformattedTokens = lexer.lex(unformatted).iterator;
  // final formattedTokens = lexer.lex(formatted).iterator;

  var unformattedOffset = 0;
  var formattedOffset = 0;
  final edits = <TextEdit>[];

  /// Helper for comparing whitespace and appending an edit.
  void addEditFor(
    int unformattedStart,
    int unformattedEnd,
    int formattedStart,
    int formattedEnd,
  ) {
    if (rangeStart != null && rangeEnd != null) {
      // If we're formatting only a range, skip over any segments that don't fall
      // entirely within that range.
      if (unformattedStart < rangeStart.result ||
          unformattedEnd > rangeEnd.result) {
        return;
      }
    }

    final unformattedWhitespace =
        unformatted.substring(unformattedStart, unformattedEnd);
    final formattedWhitespace =
        formatted.substring(formattedStart, formattedEnd);

    if (unformattedWhitespace == formattedWhitespace) {
      return;
    }

    // Validate we didn't find more than whitespace. If this occurs, it's likely
    // the token offsets used were incorrect. In this case it's better to not
    // modify the code than potentially remove something important.
    if (unformattedWhitespace.trim().isNotEmpty ||
        formattedWhitespace.trim().isNotEmpty) {
      return;
    }

    var startOffset = unformattedStart;
    var endOffset = unformattedEnd;
    var newText = formattedWhitespace;

    // Simplify some common cases where the new whitespace is a subset of
    // the old.
    if (formattedWhitespace.isNotEmpty) {
      if (unformattedWhitespace.startsWith(formattedWhitespace)) {
        startOffset = unformattedStart + formattedWhitespace.length;
        newText = '';
      } else if (unformattedWhitespace.endsWith(formattedWhitespace)) {
        endOffset = unformattedEnd - formattedWhitespace.length;
        newText = '';
      }
    }

    // Finally, append the edit for this whitespace.
    // Note: As with all LSP edits, offsets are based on the original location
    // as they are applied in one shot. They should not account for the previous
    // edits in the same set.
    edits.add(TextEdit(
      range: Range(
        start: toPosition(lineInfo.getLocation(startOffset)),
        end: toPosition(lineInfo.getLocation(endOffset)),
      ),
      newText: newText,
    ));
  }

  // Process the whitespace before each token.
  bool unformattedHasMore, formattedHasMore;
  while ((unformattedHasMore =
          unformattedTokens.moveNext()) & // Don't short-circuit
      (formattedHasMore = formattedTokens.moveNext())) {
    final unformattedToken = unformattedTokens.current;
    final formattedToken = formattedTokens.current;

    if (unformattedToken.lexeme != formattedToken.lexeme) {
      // If the token lexems do not match, there is a difference in the parsed
      // token streams (this should not ordinarily happen) so fall back to a
      // full edit.
      return success(_generateFullEdit(lineInfo, unformatted, formatted));
    }

    addEditFor(
      unformattedOffset,
      unformattedToken.offset,
      formattedOffset,
      formattedToken.offset,
    );

    // When range formatting, if we've processed a token that ends after the
    // range then there can't be any more relevant edits and we can return early.
    if (rangeEnd != null && unformattedToken.end > rangeEnd.result) {
      return success(edits);
    }

    unformattedOffset = unformattedToken.end;
    formattedOffset = formattedToken.end;
  }

  // If we got here and either of the streams still have tokens, something
  // did not match so fall back to a full edit.
  if (unformattedHasMore || formattedHasMore) {
    return success(_generateFullEdit(lineInfo, unformatted, formatted));
  }

  // Finally, handle any whitespace that was after the last token.
  addEditFor(
    unformattedOffset,
    unformatted.length,
    formattedOffset,
    formatted.length,
  );

  return success(edits);
}

/// Iterates over a token stream returning all tokens including comments.
Iterable<Token> _iterateAllTokens(Token token) sync* {
  while (token.type != Semantic.endOfFile) {
    // var commentToken = token.precedingComments;
    // while (commentToken != null) {
    //   yield commentToken;
    //   commentToken = commentToken.next;
    // }
    yield token;
    token = token.next;
  }
}

/// Helper class that bundles up all information required when converting server
/// SourceEdits into LSP-compatible WorkspaceEdits.
class FileEditInformation {
  final OptionalVersionedTextDocumentIdentifier doc;
  final LineInfo lineInfo;
  final List<client.SourceEdit> edits;
  final bool newFile;

  /// The selection offset, relative to the edit.
  final int selectionOffsetRelative;
  final int selectionLength;

  FileEditInformation(this.doc, this.lineInfo, this.edits,
      {this.newFile = false,
      this.selectionOffsetRelative,
      this.selectionLength});
}
