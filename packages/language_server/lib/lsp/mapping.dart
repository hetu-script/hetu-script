// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// import 'dart:math';

// import 'package:meta/meta.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/analyzer.dart';

import '../protocol/protocol_custom_generated.dart' as lsp;
import '../protocol/protocol_generated.dart' as lsp;
import '../protocol/protocol_special.dart';
import '../protocol/protocol_common.dart';
// import 'protocol/protocol_special.dart' as lsp;
import 'capability/client_capabilities.dart';
import 'constants.dart';
import 'lsp_analysis_server.dart';
// import 'collections.dart';
import 'source_edits.dart';
// import 'package:analysis_server/src/protocol_server.dart' as server hide AnalysisError;
// import 'package:analysis_server/src/search/workspace_symbols.dart' as server show DeclarationKind;
// import 'package:analyzer/dart/analysis/results.dart' as server;
// import 'package:analyzer/diagnostic/diagnostic.dart' as analyzer;
// import 'package:analyzer/error/error.dart' as server;
// import 'package:analyzer/source/line_info.dart' as server;
// import 'package:analyzer/source/source_range.dart' as server;
// import 'package:analyzer/src/error/codes.dart';
// import 'package:analyzer/src/services/available_declarations.dart';
// import 'package:analyzer/src/services/available_declarations.dart' as dec;
// import '../utils/pair.dart';

// const diagnosticTagsForErrorCode = <ErrorCode, List<lsp.DiagnosticTag>>{
//   HintCode.DEAD_CODE: [lsp.DiagnosticTag.Unnecessary],
//   HintCode.DEPRECATED_MEMBER_USE: [lsp.DiagnosticTag.Deprecated],
//   HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE: [
//     lsp.DiagnosticTag.Deprecated
//   ],
//   HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE: [
//     lsp.DiagnosticTag.Deprecated
//   ],
//   HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE: [lsp.DiagnosticTag.Deprecated],
// };

const languageSourceName = 'hetu';

Either2<String, lsp.MarkupContent> asStringOrMarkupContent(
    Set<lsp.MarkupKind> preferredFormats, String content) {
  if (content == null) {
    return null;
  }

  return preferredFormats == null
      ? Either2<String, lsp.MarkupContent>.t1(content)
      : Either2<String, lsp.MarkupContent>.t2(
          _asMarkup(preferredFormats, content));
}

/// Builds an LSP snippet string with supplied ranges as tabstops.
String buildSnippetStringWithTabStops(
  String text,
  List<int> offsetLengthPairs,
) {
  text ??= '';
  offsetLengthPairs ??= const [];

  String escape(String input) => input.replaceAllMapped(
        RegExp(r'[$}\\]'), // Replace any of $ } \
        (c) => '\\${c[0]}', // Prefix with a backslash
      );

  // Snippets syntax is documented in the LSP spec:
  // https://microsoft.github.io/language-server-protocol/specifications/specification-current/#snippet_syntax
  //
  // $1, $2, etc. are used for tab stops and ${1:foo} inserts a placeholder of foo.

  final output = [];
  var offset = 0;

  // When there's only a single tabstop, it should be ${0} as this is treated
  // specially as the final cursor position (if we use 1, the editor will insert
  // a 0 at the end of the string which is not what we expect).
  // When there are multiple, start with ${1} since these are placeholders the
  // user can tab through and the editor-inserted ${0} at the end is expected.
  var tabStopNumber = offsetLengthPairs.length <= 2 ? 0 : 1;

  for (var i = 0; i < offsetLengthPairs.length; i += 2) {
    final pairOffset = offsetLengthPairs[i];
    final pairLength = offsetLengthPairs[i + 1];

    // Add any text that came before this tabstop to the result.
    output.add(escape(text.substring(offset, pairOffset)));

    // Add this tabstop
    final tabStopText =
        escape(text.substring(pairOffset, pairOffset + pairLength));
    output.add('\${${tabStopNumber++}:$tabStopText}');

    offset = pairOffset + pairLength;
  }

  // Add any remaining text that was after the last tabstop.
  output.add(escape(text.substring(offset)));

  return output.join('');
}

/// Creates a [WorkspaceEdit] from simple [server.SourceFileEdit]s.
///
/// Note: This code will fetch the version of each document being modified so
/// it's important to call this immediately after computing edits to ensure
/// the document is not modified before the version number is read.
lsp.WorkspaceEdit createPlainWorkspaceEdit(
    LspAnalysisServer server, List<SourceFileEdit> edits) {
  return toWorkspaceEdit(
      server.clientCapabilities,
      edits
          .map((e) => FileEditInformation(
                server.getVersionedDocumentIdentifier(e.file),
                server.getLineInfo(e.file),
                e.edits,
                // fileStamp == 1 is used by the server to indicate the file needs creating.
                newFile: e.fileStamp == -1,
              ))
          .toList());
}

/// Creates a [WorkspaceEdit] from a [server.SourceChange] that can include
/// experimental [server.SnippetTextEdit]s if the client has indicated support
/// for these in the experimental section of their client capabilities.
///
/// Note: This code will fetch the version of each document being modified so
/// it's important to call this immediately after computing edits to ensure
/// the document is not modified before the version number is read.
lsp.WorkspaceEdit createWorkspaceEdit(
    LspAnalysisServer server, SourceChange change) {
  // In order to return snippets, we must ensure we are only modifying a single
  // existing file with a single edit and that there is a linked edit group with
  // only one position and no suggestions.
  if (!server.clientCapabilities.experimentalSnippetTextEdit ||
      change.edits.length != 1 ||
      change.edits.first.fileStamp == -1 || // new file
      change.edits.first.edits.length != 1 ||
      change.linkedEditGroups.isEmpty ||
      change.linkedEditGroups.first.positions.length != 1 ||
      change.linkedEditGroups.first.suggestions.isNotEmpty) {
    return createPlainWorkspaceEdit(server, change.edits);
  }

  // Additionally, the selection must fall within the edit offset.
  final edit = change.edits.first.edits.first;
  final selectionOffset = change.linkedEditGroups.first.positions.first.offset;
  final selectionLength = change.linkedEditGroups.first.length;

  if (selectionOffset < edit.offset ||
      selectionOffset + selectionLength > edit.offset + edit.length) {
    return createPlainWorkspaceEdit(server, change.edits);
  }

  return toWorkspaceEdit(
      server.clientCapabilities,
      change.edits
          .map((e) => FileEditInformation(
                server.getVersionedDocumentIdentifier(e.file),
                server.getLineInfo(e.file),
                e.edits,
                selectionOffsetRelative: selectionOffset - edit.offset,
                selectionLength: selectionLength,
                newFile: e.fileStamp == -1,
              ))
          .toList());
}

// CompletionItemKind declarationKindToCompletionItemKind(
//   Set<CompletionItemKind> supportedCompletionKinds,
//   dec.DeclarationKind kind,
// ) {
//   bool isSupported(CompletionItemKind kind) =>
//       supportedCompletionKinds.contains(kind);

//   List<CompletionItemKind> getKindPreferences() {
//     switch (kind) {
//       case dec.DeclarationKind.CLASS:
//       case dec.DeclarationKind.CLASS_TYPE_ALIAS:
//       case dec.DeclarationKind.MIXIN:
//         return const [CompletionItemKind.Class];
//       case dec.DeclarationKind.CONSTRUCTOR:
//         return const [CompletionItemKind.Constructor];
//       case dec.DeclarationKind.ENUM:
//       case dec.DeclarationKind.ENUM_CONSTANT:
//         return const [CompletionItemKind.Enum];
//       case dec.DeclarationKind.FUNCTION:
//         return const [CompletionItemKind.Function];
//       case dec.DeclarationKind.FUNCTION_TYPE_ALIAS:
//         return const [CompletionItemKind.Class];
//       case dec.DeclarationKind.GETTER:
//         return const [CompletionItemKind.Property];
//       case dec.DeclarationKind.SETTER:
//         return const [CompletionItemKind.Property];
//       case dec.DeclarationKind.VARIABLE:
//         return const [CompletionItemKind.Variable];
//       default:
//         return const [];
//     }
//   }

//   return getKindPreferences().firstWhere(isSupported, orElse: () => null);
// }

// SymbolKind declarationKindToSymbolKind(
//   Set<SymbolKind> supportedSymbolKinds,
//   server.DeclarationKind kind,
// ) {
//   bool isSupported(SymbolKind kind) => supportedSymbolKinds.contains(kind);

//   List<SymbolKind> getKindPreferences() {
//     switch (kind) {
//       case server.DeclarationKind.CLASS:
//       case server.DeclarationKind.CLASS_TYPE_ALIAS:
//         return const [lsp.SymbolKind.Class];
//       case server.DeclarationKind.CONSTRUCTOR:
//         return const [lsp.SymbolKind.Constructor];
//       case server.DeclarationKind.ENUM:
//         return const [lsp.SymbolKind.Enum];
//       case server.DeclarationKind.ENUM_CONSTANT:
//         return const [lsp.SymbolKind.EnumMember, SymbolKind.Enum];
//       case server.DeclarationKind.EXTENSION:
//         return const [lsp.SymbolKind.Class];
//       case server.DeclarationKind.FIELD:
//         return const [lsp.SymbolKind.Field];
//       case server.DeclarationKind.FUNCTION:
//         return const [lsp.SymbolKind.Function];
//       case server.DeclarationKind.FUNCTION_TYPE_ALIAS:
//         return const [lsp.SymbolKind.Class];
//       case server.DeclarationKind.GETTER:
//         return const [lsp.SymbolKind.Property];
//       case server.DeclarationKind.METHOD:
//         return const [lsp.SymbolKind.Method];
//       case server.DeclarationKind.MIXIN:
//         return const [lsp.SymbolKind.Class];
//       case server.DeclarationKind.SETTER:
//         return const [lsp.SymbolKind.Property];
//       case server.DeclarationKind.VARIABLE:
//         return const [lsp.SymbolKind.Variable];
//       default:
//         // Assert that we only get here if kind=null. If it's anything else
//         // then we're missing a mapping from above.
//         assert(kind == null, 'Unexpected declaration kind $kind');
//         return const [];
//     }
//   }

//   // LSP requires we specify *some* kind, so in the case where the above code doesn't
//   // match we'll just have to send a value to avoid a crash.
//   return getKindPreferences()
//       .firstWhere(isSupported, orElse: () => SymbolKind.Obj);
// }

// CompletionItem declarationToCompletionItem(
//   LspClientCapabilities capabilities,
//   String file,
//   int offset,
//   server.IncludedSuggestionSet includedSuggestionSet,
//   Library library,
//   Map<String, int> tagBoosts,
//   server.LineInfo lineInfo,
//   dec.Declaration declaration,
//   int replacementOffset,
//   int insertLength,
//   int replacementLength, {
//   @required bool includeCommitCharacters,
//   @required bool completeFunctionCalls,
// }) {
//   final supportsSnippets = capabilities.completionSnippets;

//   String completion;
//   switch (declaration.kind) {
//     case DeclarationKind.ENUM_CONSTANT:
//       completion = '${declaration.parent.name}.${declaration.name}';
//       break;
//     case DeclarationKind.GETTER:
//     case DeclarationKind.FIELD:
//       completion = declaration.parent != null &&
//               declaration.parent.name != null &&
//               declaration.parent.name.isNotEmpty
//           ? '${declaration.parent.name}.${declaration.name}'
//           : declaration.name;
//       break;
//     case DeclarationKind.CONSTRUCTOR:
//       completion = declaration.parent.name;
//       if (declaration.name.isNotEmpty) {
//         completion += '.${declaration.name}';
//       }
//       break;
//     default:
//       completion = declaration.name;
//       break;
//   }
//   // By default, label is the same as the completion text, but may be added to
//   // later (parens/snippets).
//   var label = completion;

//   // isCallable is used to suffix the label with parens so it's clear the item
//   // is callable.
//   final declarationKind = declaration.kind;
//   final isCallable = declarationKind == DeclarationKind.CONSTRUCTOR ||
//       declarationKind == DeclarationKind.FUNCTION ||
//       declarationKind == DeclarationKind.METHOD;

//   if (isCallable) {
//     label += declaration.parameterNames?.isNotEmpty ?? false ? '(…)' : '()';
//   }

//   final insertTextInfo = _buildInsertText(
//     supportsSnippets: supportsSnippets,
//     includeCommitCharacters: includeCommitCharacters,
//     completeFunctionCalls: completeFunctionCalls,
//     isCallable: isCallable,
//     // For SuggestionSets, we don't have a CompletionKind to check if it's
//     // an invoke, but since they do not show in show/hide combinators
//     // we can assume if an item is callable it's probably being used in a context
//     // that can invoke it.
//     isInvocation: isCallable,
//     defaultArgumentListString: declaration.defaultArgumentListString,
//     defaultArgumentListTextRanges: declaration.defaultArgumentListTextRanges,
//     completion: completion,
//     selectionOffset: 0,
//     selectionLength: 0,
//   );
//   final insertText = insertTextInfo.first;
//   final insertTextFormat = insertTextInfo.last;
//   final isMultilineCompletion = insertText.contains('\n');

//   final supportsDeprecatedFlag = capabilities.completionDeprecatedFlag;
//   final supportsDeprecatedTag =
//       capabilities.completionItemTags.contains(CompletionItemTag.Deprecated);
//   final supportsAsIsInsertMode =
//       capabilities.completionInsertTextModes.contains(InsertTextMode.asIs);

//   final completionKind = declarationKindToCompletionItemKind(
//       capabilities.completionItemKinds, declaration.kind);

//   var relevanceBoost = 0;
//   if (declaration.relevanceTags != null) {
//     declaration.relevanceTags.forEach(
//         (t) => relevanceBoost = max(relevanceBoost, tagBoosts[t] ?? 0));
//   }
//   final itemRelevance = includedSuggestionSet.relevance + relevanceBoost;

//   // Because we potentially send thousands of these items, we should minimise
//   // the generated JSON as much as possible - for example using nulls in place
//   // of empty lists/false where possible.
//   return CompletionItem(
//     label: label,
//     kind: completionKind,
//     tags: nullIfEmpty([
//       if (supportsDeprecatedTag && declaration.isDeprecated)
//         CompletionItemTag.Deprecated
//     ]),
//     commitCharacters:
//         includeCommitCharacters ? dartCompletionCommitCharacters : null,
//     detail: getDeclarationCompletionDetail(declaration, completionKind,
//         supportsDeprecatedFlag || supportsDeprecatedTag),
//     deprecated:
//         supportsDeprecatedFlag && declaration.isDeprecated ? true : null,
//     // Relevance is a number, highest being best. LSP does text sort so subtract
//     // from a large number so that a text sort will result in the correct order.
//     // 555 -> 999455
//     //  10 -> 999990
//     //   1 -> 999999
//     sortText: (1000000 - itemRelevance).toString(),
//     filterText: completion != label
//         ? completion
//         : null, // filterText uses label if not set
//     insertText: insertText != label
//         ? insertText
//         : null, // insertText uses label if not set
//     insertTextFormat: insertTextFormat != InsertTextFormat.PlainText
//         ? insertTextFormat
//         : null, // Defaults to PlainText if not supplied
//     insertTextMode: supportsAsIsInsertMode && isMultilineCompletion
//         ? InsertTextMode.asIs
//         : null,
//     // data, used for completionItem/resolve.
//     data: DartCompletionItemResolutionInfo(
//         file: file,
//         offset: offset,
//         libId: includedSuggestionSet.id,
//         displayUri: includedSuggestionSet.displayUri ?? library.uri?.toString(),
//         rOffset: replacementOffset,
//         iLength: insertLength,
//         rLength: replacementLength),
//   );
// }

// CompletionItemKind elementKindToCompletionItemKind(
//   Set<CompletionItemKind> supportedCompletionKinds,
//   ElementKind kind,
// ) {
//   bool isSupported(CompletionItemKind kind) =>
//       supportedCompletionKinds.contains(kind);

//   List<CompletionItemKind> getKindPreferences() {
//     switch (kind) {
//       case ElementKind.CLASS:
//       case ElementKind.CLASS_TYPE_ALIAS:
//         return const [CompletionItemKind.Class];
//       case ElementKind.COMPILATION_UNIT:
//         return const [CompletionItemKind.Module];
//       case ElementKind.CONSTRUCTOR:
//       case ElementKind.CONSTRUCTOR_INVOCATION:
//         return const [CompletionItemKind.Constructor];
//       case ElementKind.ENUM:
//       case ElementKind.ENUM_CONSTANT:
//         return const [CompletionItemKind.Enum];
//       case ElementKind.FIELD:
//         return const [CompletionItemKind.Field];
//       case ElementKind.FILE:
//         return const [CompletionItemKind.File];
//       case ElementKind.FUNCTION:
//         return const [CompletionItemKind.Function];
//       case ElementKind.FUNCTION_TYPE_ALIAS:
//         return const [CompletionItemKind.Class];
//       case ElementKind.GETTER:
//         return const [CompletionItemKind.Property];
//       case ElementKind.LABEL:
//         // There isn't really a good CompletionItemKind for labels so we'll
//         // just use the Text option.
//         return const [CompletionItemKind.Text];
//       case ElementKind.LIBRARY:
//         return const [CompletionItemKind.Module];
//       case ElementKind.LOCAL_VARIABLE:
//         return const [CompletionItemKind.Variable];
//       case ElementKind.METHOD:
//         return const [CompletionItemKind.Method];
//       case ElementKind.MIXIN:
//         return const [CompletionItemKind.Class];
//       case ElementKind.PARAMETER:
//       case ElementKind.PREFIX:
//         return const [CompletionItemKind.Variable];
//       case ElementKind.SETTER:
//         return const [CompletionItemKind.Property];
//       case ElementKind.TOP_LEVEL_VARIABLE:
//         return const [CompletionItemKind.Variable];
//       case ElementKind.TYPE_PARAMETER:
//         return const [
//           CompletionItemKind.TypeParameter,
//           CompletionItemKind.Variable,
//         ];
//       case ElementKind.UNIT_TEST_GROUP:
//       case ElementKind.UNIT_TEST_TEST:
//         return const [CompletionItemKind.Method];
//       default:
//         return const [];
//     }
//   }

//   return getKindPreferences().firstWhere(isSupported, orElse: () => null);
// }

lsp.SymbolKind elementKindToSymbolKind(
  Set<lsp.SymbolKind> supportedSymbolKinds,
  ElementKind kind,
) {
  bool isSupported(lsp.SymbolKind kind) => supportedSymbolKinds.contains(kind);

  List<lsp.SymbolKind> getKindPreferences() {
    switch (kind) {
      case ElementKind.CLASS:
      case ElementKind.CLASS_TYPE_ALIAS:
        return const [lsp.SymbolKind.Class];
      case ElementKind.COMPILATION_UNIT:
        return const [lsp.SymbolKind.Module];
      case ElementKind.CONSTRUCTOR:
      case ElementKind.CONSTRUCTOR_INVOCATION:
        return const [lsp.SymbolKind.Constructor];
      case ElementKind.ENUM:
        return const [lsp.SymbolKind.Enum];
      case ElementKind.ENUM_CONSTANT:
        return const [lsp.SymbolKind.EnumMember, lsp.SymbolKind.Enum];
      case ElementKind.EXTENSION:
        return const [lsp.SymbolKind.Namespace];
      case ElementKind.FIELD:
        return const [lsp.SymbolKind.Field];
      case ElementKind.FILE:
        return const [lsp.SymbolKind.File];
      case ElementKind.FUNCTION:
      case ElementKind.FUNCTION_INVOCATION:
        return const [lsp.SymbolKind.Function];
      case ElementKind.FUNCTION_TYPE_ALIAS:
        return const [lsp.SymbolKind.Class];
      case ElementKind.GETTER:
        return const [lsp.SymbolKind.Property];
      case ElementKind.LABEL:
        // There isn't really a good SymbolKind for labels so we'll
        // just use the Null option.
        return const [lsp.SymbolKind.Null];
      case ElementKind.LIBRARY:
        return const [lsp.SymbolKind.Namespace];
      case ElementKind.LOCAL_VARIABLE:
        return const [lsp.SymbolKind.Variable];
      case ElementKind.METHOD:
        return const [lsp.SymbolKind.Method];
      case ElementKind.MIXIN:
        return const [lsp.SymbolKind.Class];
      case ElementKind.PARAMETER:
      case ElementKind.PREFIX:
        return const [lsp.SymbolKind.Variable];
      case ElementKind.SETTER:
        return const [lsp.SymbolKind.Property];
      case ElementKind.TOP_LEVEL_VARIABLE:
        return const [lsp.SymbolKind.Variable];
      case ElementKind.TYPE_PARAMETER:
        return const [
          lsp.SymbolKind.TypeParameter,
          lsp.SymbolKind.Variable,
        ];
      case ElementKind.UNIT_TEST_GROUP:
      case ElementKind.UNIT_TEST_TEST:
        return const [lsp.SymbolKind.Method];
      default:
        // Assert that we only get here if kind=null. If it's anything else
        // then we're missing a mapping from above.
        assert(kind == null, 'Unexpected element kind $kind');
        return const [];
    }
  }

  // LSP requires we specify *some* kind, so in the case where the above code doesn't
  // match we'll just have to send a value to avoid a crash.
  return getKindPreferences()
      .firstWhere(isSupported, orElse: () => lsp.SymbolKind.Obj);
}

// String getCompletionDetail(
//   server.CompletionSuggestion suggestion,
//   CompletionItemKind completionKind,
//   bool supportsDeprecated,
// ) {
//   final hasElement = suggestion.element != null;
//   final hasParameters = hasElement &&
//       suggestion.element.parameters != null &&
//       suggestion.element.parameters.isNotEmpty;
//   final hasReturnType = hasElement &&
//       suggestion.element.returnType != null &&
//       suggestion.element.returnType.isNotEmpty;
//   final hasParameterType =
//       suggestion.parameterType != null && suggestion.parameterType.isNotEmpty;

//   final prefix =
//       supportsDeprecated || !suggestion.isDeprecated ? '' : '(Deprecated) ';

//   if (completionKind == CompletionItemKind.Property) {
//     // Setters appear as methods with one arg but they also cause getters to not
//     // appear in the completion list, so displaying them as setters is misleading.
//     // To avoid this, always show only the return type, whether it's a getter
//     // or a setter.
//     return prefix +
//         (suggestion.element.kind == ElementKind.GETTER
//             ? suggestion.element.returnType
//             // Don't assume setters always have parameters
//             // See https://github.com/dart-lang/sdk/issues/27747
//             : suggestion.element.parameters != null &&
//                     suggestion.element.parameters.isNotEmpty
//                 // Extract the type part from '(MyType value)`
//                 ? suggestion.element.parameters.substring(
//                     1, suggestion.element.parameters.lastIndexOf(' '))
//                 : '');
//   } else if (hasParameters && hasReturnType) {
//     return '$prefix${suggestion.element.parameters} → ${suggestion.element.returnType}';
//   } else if (hasReturnType) {
//     return '$prefix${suggestion.element.returnType}';
//   } else if (hasParameterType) {
//     return '$prefix${suggestion.parameterType}';
//   } else {
//     return prefix.isNotEmpty ? prefix : null;
//   }
// }

// String getDeclarationCompletionDetail(
//   dec.Declaration declaration,
//   CompletionItemKind completionKind,
//   bool supportsDeprecated,
// ) {
//   final hasParameters =
//       declaration.parameters != null && declaration.parameters.isNotEmpty;
//   final hasReturnType =
//       declaration.returnType != null && declaration.returnType.isNotEmpty;

//   final prefix =
//       supportsDeprecated || !declaration.isDeprecated ? '' : '(Deprecated) ';

//   if (completionKind == CompletionItemKind.Property) {
//     // Setters appear as methods with one arg but they also cause getters to not
//     // appear in the completion list, so displaying them as setters is misleading.
//     // To avoid this, always show only the return type, whether it's a getter
//     // or a setter.
//     var suffix = '';
//     if (declaration.kind == dec.DeclarationKind.GETTER) {
//       suffix = declaration.returnType;
//     } else {
//       // Don't assume setters always have parameters
//       // See https://github.com/dart-lang/sdk/issues/27747
//       if (declaration.parameters != null && declaration.parameters.isNotEmpty) {
//         // Extract the type part from `(MyType value)`, if there is a type.
//         var spaceIndex = declaration.parameters.lastIndexOf(' ');
//         if (spaceIndex > 0) {
//           suffix = declaration.parameters.substring(1, spaceIndex);
//         }
//       }
//     }
//     return prefix + suffix;
//   } else if (hasParameters && hasReturnType) {
//     return '$prefix${declaration.parameters} → ${declaration.returnType}';
//   } else if (hasReturnType) {
//     return '$prefix${declaration.returnType}';
//   } else {
//     return prefix.isNotEmpty ? prefix : null;
//   }
// }

// List<lsp.DiagnosticTag> getDiagnosticTags(
//     Set<lsp.DiagnosticTag> supportedTags, HTAnalysisError error) {
//   if (supportedTags == null) {
//     return null;
//   }

//   final tags = diagnosticTagsForErrorCode[error.errorCode]
//       ?.where(supportedTags.contains)
//       ?.toList();

//   return tags != null && tags.isNotEmpty ? tags : null;
// }

bool isHetuDocument(lsp.TextDocumentIdentifier doc) =>
    doc.uri.endsWith(HTResource.hetuModule) ||
    doc.uri.endsWith(HTResource.hetuScript);

// Location navigationTargetToLocation(
//   String targetFilePath,
//   server.NavigationTarget target,
//   server.LineInfo targetLineInfo,
// ) {
//   if (targetLineInfo == null) {
//     return null;
//   }

//   return Location(
//     uri: Uri.file(targetFilePath).toString(),
//     range: toRange(targetLineInfo, target.offset, target.length),
//   );
// }

// LocationLink navigationTargetToLocationLink(
//   server.NavigationRegion region,
//   server.LineInfo regionLineInfo,
//   String targetFilePath,
//   server.NavigationTarget target,
//   server.LineInfo targetLineInfo,
// ) {
//   if (regionLineInfo == null || targetLineInfo == null) {
//     return null;
//   }

//   final nameRange = toRange(targetLineInfo, target.offset, target.length);
//   final codeRange = target.codeOffset != null && target.codeLength != null
//       ? toRange(targetLineInfo, target.codeOffset, target.codeLength)
//       : nameRange;

//   return LocationLink(
//     originSelectionRange: toRange(regionLineInfo, region.offset, region.length),
//     targetUri: Uri.file(targetFilePath).toString(),
//     targetRange: codeRange,
//     targetSelectionRange: nameRange,
//   );
// }

/// Returns the file system path for a TextDocumentIdentifier.
ErrorOr<String> pathOfDoc(lsp.TextDocumentIdentifier doc) =>
    pathOfUri(Uri.tryParse(doc?.uri));

/// Returns the file system path for a TextDocumentItem.
ErrorOr<String> pathOfDocItem(lsp.TextDocumentItem doc) =>
    pathOfUri(Uri.tryParse(doc?.uri));

/// Returns the file system path for a file URI.
ErrorOr<String> pathOfUri(Uri uri) {
  if (uri == null) {
    return ErrorOr<String>.error(lsp.ResponseError(
      code: ServerErrorCodes.InvalidFilePath,
      message: 'Document URI was not supplied',
    ));
  }
  final isValidFileUri = uri?.isScheme('file') ?? false;
  if (!isValidFileUri) {
    return ErrorOr<String>.error(lsp.ResponseError(
      code: ServerErrorCodes.InvalidFilePath,
      message: 'URI was not a valid file:// URI',
      data: uri.toString(),
    ));
  }
  try {
    return ErrorOr<String>.success(uri.toFilePath());
  } catch (e) {
    // Even if tryParse() works and file == scheme, toFilePath() can throw on
    // Windows if there are invalid characters.
    return ErrorOr<String>.error(lsp.ResponseError(
        code: ServerErrorCodes.InvalidFilePath,
        message: 'File URI did not contain a valid file path',
        data: uri.toString()));
  }
}

/// Returns a list of AnalysisErrors corresponding to the given list of Engine
/// errors.
List<AnalysisError> doAnalysisError_listFromEngine(
    HTSourceAnalysisResult result) {
  return mapEngineErrors(result, result.errors, newAnalysisError_fromEngine);
}

/// Construct based on error information from the analyzer engine.
///
/// If an [errorSeverity] is specified, it will override the one in [error].
AnalysisError newAnalysisError_fromEngine(
    HTSourceAnalysisResult result, HTAnalysisError error,
    [ErrorSeverity errorSeverity]) {
  // prepare location
  Location location;
  {
    var file = error.filename;
    var offset = error.offset;
    var length = error.length;
    var lineInfo = result.lineInfo;

    var startLocation = lineInfo.getLocation(offset);
    var startLine = startLocation.line;
    var startColumn = startLocation.column;

    var endLocation = lineInfo.getLocation(offset + length);
    var endLine = endLocation.line;
    var endColumn = endLocation.column;

    location = Location(
        file, offset, length, startLine, startColumn, endLine, endColumn);
  }

  // Default to the error's severity if none is specified.
  errorSeverity ??= error.severity;

  // done
  var severity = AnalysisErrorSeverity(errorSeverity.name);
  var type = AnalysisErrorType(error.type.name);
  var message = error.message;
  var code = error.name.toLowerCase();
  List<DiagnosticMessage> contextMessages;
  if (error.contextMessages.isNotEmpty) {
    contextMessages = error.contextMessages
        .map((message) => newDiagnosticMessage(result, message))
        .toList();
  }
  var correction = error.correction;
  var hasFix = false;
  // var fix = hasFix(error.errorCode);
  var url;
  // var url = error.url;
  return AnalysisError(severity, type, location, message, code,
      contextMessages: contextMessages,
      correction: correction,
      hasFix: hasFix,
      url: url);
}

/// Create a DiagnosticMessage based on an [engine.DiagnosticMessage].
DiagnosticMessage newDiagnosticMessage(
    HTSourceAnalysisResult result, HTDiagnosticMessage message) {
  var file = message.filename;
  var offset = message.offset;
  var length = message.length;

  var startLocation = result.lineInfo.getLocation(offset);
  var startLine = startLocation.line;
  var startColumn = startLocation.column;

  var endLocation = result.lineInfo.getLocation(offset + length);
  var endLine = endLocation.line;
  var endColumn = endLocation.column;

  return DiagnosticMessage(
      message.message,
      Location(
          file, offset, length, startLine, startColumn, endLine, endColumn));
}

/// Translates engine errors through the ErrorProcessor.
List<T> mapEngineErrors<T>(
    HTSourceAnalysisResult result,
    List<HTAnalysisError> errors,
    T Function(HTSourceAnalysisResult result, HTAnalysisError error,
            [ErrorSeverity errorSeverity])
        constructor) {
  var serverErrors = <T>[];
  for (var error in errors) {
    var processor = ErrorProcessor.getProcessor(result.analyzer, error);
    if (processor != null) {
      var severity = processor.severity;
      // Errors with null severity are filtered out.
      if (severity != null) {
        // Specified severities override.
        serverErrors.add(constructor(result, error, severity));
      }
    } else {
      serverErrors.add(constructor(result, error));
    }
  }
  return serverErrors;
}

lsp.Diagnostic analysisErrorToDiagnostic(
  LineInfo Function(String) getLineInfo,
  AnalysisError error,
) {
  List<lsp.DiagnosticRelatedInformation> relatedInformation;
  if (error.contextMessages != null && error.contextMessages.isNotEmpty) {
    relatedInformation = error.contextMessages
        .map((message) =>
            messageToDiagnosticRelatedInformation(getLineInfo, message))
        .toList();
  }

  var message = error.message;
  if (error.correction != null) {
    message = '$message\n${error.correction}';
  }

  var lineInfo = getLineInfo(error.location.file);
  return lsp.Diagnostic(
    range: toRange(lineInfo, error.location.offset, error.location.length),
    severity: analysisErrorSeverityToDiagnosticSeverity(error.severity),
    code: error.code,
    source: languageSourceName,
    message: message,
    relatedInformation: relatedInformation,
  );
}

lsp.DiagnosticRelatedInformation messageToDiagnosticRelatedInformation(
    LineInfo Function(String) getLineInfo, DiagnosticMessage message) {
  var file = message.location.file;
  var lineInfo = getLineInfo(file);
  return lsp.DiagnosticRelatedInformation(
      location: lsp.Location(
        uri: Uri.file(file).toString(),
        range: toRange(
          lineInfo,
          message.location.offset,
          message.location.length,
        ),
      ),
      message: message.message);
}

lsp.DiagnosticSeverity analysisErrorSeverityToDiagnosticSeverity(
    AnalysisErrorSeverity severity) {
  switch (severity) {
    case AnalysisErrorSeverity.ERROR:
      return lsp.DiagnosticSeverity.Error;
    case AnalysisErrorSeverity.WARNING:
      return lsp.DiagnosticSeverity.Warning;
    case AnalysisErrorSeverity.INFO:
      return lsp.DiagnosticSeverity.Information;
    // Note: LSP also supports "Hint", but they won't render in things like the
    // VS Code errors list as they're apparently intended to communicate
    // non-visible diagnostics back (for example, if you wanted to grey out
    // unreachable code without producing an item in the error list).
    default:
      throw 'Unknown AnalysisErrorSeverity: $severity';
  }
}

// Location searchResultToLocation(
//     SearchResult result, LineInfo lineInfo) {
//   final location = result.location;

//   if (lineInfo == null) {
//     return null;
//   }

//   return Location(
//     uri: Uri.file(result.location.file).toString(),
//     range: toRange(lineInfo, location.offset, location.length),
//   );
// }

// CompletionItemKind suggestionKindToCompletionItemKind(
//   Set<CompletionItemKind> supportedCompletionKinds,
//   server.CompletionSuggestionKind kind,
//   String label,
// ) {
//   bool isSupported(CompletionItemKind kind) =>
//       supportedCompletionKinds.contains(kind);

//   List<CompletionItemKind> getKindPreferences() {
//     switch (kind) {
//       case server.CompletionSuggestionKind.ARGUMENT_LIST:
//         return const [CompletionItemKind.Variable];
//       case server.CompletionSuggestionKind.IMPORT:
//         // For package/relative URIs, we can send File/Folder kinds for better icons.
//         if (!label.startsWith('dart:')) {
//           return label.endsWith('.dart')
//               ? const [
//                   CompletionItemKind.File,
//                   CompletionItemKind.Module,
//                 ]
//               : const [
//                   CompletionItemKind.Folder,
//                   CompletionItemKind.Module,
//                 ];
//         }
//         return const [CompletionItemKind.Module];
//       case server.CompletionSuggestionKind.IDENTIFIER:
//         return const [CompletionItemKind.Variable];
//       case server.CompletionSuggestionKind.INVOCATION:
//         return const [CompletionItemKind.Method];
//       case server.CompletionSuggestionKind.KEYWORD:
//         return const [CompletionItemKind.Keyword];
//       case server.CompletionSuggestionKind.NAMED_ARGUMENT:
//         return const [CompletionItemKind.Variable];
//       case server.CompletionSuggestionKind.OPTIONAL_ARGUMENT:
//         return const [CompletionItemKind.Variable];
//       case server.CompletionSuggestionKind.PARAMETER:
//         return const [CompletionItemKind.Value];
//       case server.CompletionSuggestionKind.PACKAGE_NAME:
//         return const [CompletionItemKind.Module];
//       default:
//         return const [];
//     }
//   }

//   return getKindPreferences().firstWhere(isSupported, orElse: () => null);
// }

// ClosingLabel toClosingLabel(
//         server.LineInfo lineInfo, server.ClosingLabel label) =>
//     ClosingLabel(
//         range: toRange(lineInfo, label.offset, label.length),
//         label: label.label);

// CodeActionKind toCodeActionKind(String id, CodeActionKind fallback) {
//   if (id == null) {
//     return fallback;
//   }
//   // Dart fixes and assists start with "dart.assist." and "dart.fix." but in LSP
//   // we want to use the predefined prefixes for CodeActions.
//   final newId = id
//       .replaceAll('dart.assist', CodeActionKind.Refactor.toString())
//       .replaceAll('dart.fix', CodeActionKind.QuickFix.toString())
//       .replaceAll('analysisOptions.assist', CodeActionKind.Refactor.toString())
//       .replaceAll('analysisOptions.fix', CodeActionKind.QuickFix.toString());
//   return CodeActionKind(newId);
// }

// CompletionItem toCompletionItem(
//   LspClientCapabilities capabilities,
//   server.LineInfo lineInfo,
//   server.CompletionSuggestion suggestion,
//   int replacementOffset,
//   int insertLength,
//   int replacementLength, {
//   @required bool includeCommitCharacters,
//   @required bool completeFunctionCalls,
//   Object resolutionData,
// }) {
//   // Build separate display and filter labels. Displayed labels may have additional
//   // info appended (for example '(...)' on callables) that should not be included
//   // in filterText.
//   var label = suggestion.displayText ?? suggestion.completion;
//   final filterText = label;

//   // Trim any trailing comma from the (displayed) label.
//   if (label.endsWith(',')) {
//     label = label.substring(0, label.length - 1);
//   }

//   // isCallable is used to suffix the label with parens so it's clear the item
//   // is callable.
//   //
//   // isInvocation means the location at which it's used is an invoke (and
//   // therefore it is appropriate to include the parens/parameters in the
//   // inserted text).
//   //
//   // In the case of show combinators, the parens will still be shown to indicate
//   // functions but they should not be included in the completions.
//   final elementKind = suggestion.element?.kind;
//   final isCallable = elementKind == ElementKind.CONSTRUCTOR ||
//       elementKind == ElementKind.FUNCTION ||
//       elementKind == ElementKind.METHOD;
//   final isInvocation =
//       suggestion.kind == server.CompletionSuggestionKind.INVOCATION;

//   if (suggestion.displayText == null && isCallable) {
//     label += suggestion.parameterNames?.isNotEmpty ?? false ? '(…)' : '()';
//   }

//   final supportsCompletionDeprecatedFlag =
//       capabilities.completionDeprecatedFlag;
//   final supportsDeprecatedTag =
//       capabilities.completionItemTags.contains(CompletionItemTag.Deprecated);
//   final formats = capabilities.completionDocumentationFormats;
//   final supportsSnippets = capabilities.completionSnippets;
//   final supportsInsertReplace = capabilities.insertReplaceCompletionRanges;
//   final supportsAsIsInsertMode =
//       capabilities.completionInsertTextModes.contains(InsertTextMode.asIs);

//   final completionKind = suggestion.element != null
//       ? elementKindToCompletionItemKind(
//           capabilities.completionItemKinds, suggestion.element.kind)
//       : suggestionKindToCompletionItemKind(
//           capabilities.completionItemKinds, suggestion.kind, label);

//   final insertTextInfo = _buildInsertText(
//     supportsSnippets: supportsSnippets,
//     includeCommitCharacters: includeCommitCharacters,
//     completeFunctionCalls: completeFunctionCalls,
//     isCallable: isCallable,
//     isInvocation: isInvocation,
//     defaultArgumentListString: suggestion.defaultArgumentListString,
//     defaultArgumentListTextRanges: suggestion.defaultArgumentListTextRanges,
//     completion: suggestion.completion,
//     selectionOffset: suggestion.selectionOffset,
//     selectionLength: suggestion.selectionLength,
//   );
//   final insertText = insertTextInfo.first;
//   final insertTextFormat = insertTextInfo.last;
//   final isMultilineCompletion = insertText.contains('\n');

//   // Because we potentially send thousands of these items, we should minimise
//   // the generated JSON as much as possible - for example using nulls in place
//   // of empty lists/false where possible.
//   return CompletionItem(
//     label: label,
//     kind: completionKind,
//     tags: nullIfEmpty([
//       if (supportsDeprecatedTag && suggestion.isDeprecated)
//         CompletionItemTag.Deprecated
//     ]),
//     commitCharacters:
//         includeCommitCharacters ? dartCompletionCommitCharacters : null,
//     data: resolutionData,
//     detail: getCompletionDetail(suggestion, completionKind,
//         supportsCompletionDeprecatedFlag || supportsDeprecatedTag),
//     documentation:
//         asStringOrMarkupContent(formats, cleanDartdoc(suggestion.docComplete)),
//     deprecated: supportsCompletionDeprecatedFlag && suggestion.isDeprecated
//         ? true
//         : null,
//     // Relevance is a number, highest being best. LSP does text sort so subtract
//     // from a large number so that a text sort will result in the correct order.
//     // 555 -> 999455
//     //  10 -> 999990
//     //   1 -> 999999
//     sortText: (1000000 - suggestion.relevance).toString(),
//     filterText: filterText != label
//         ? filterText
//         : null, // filterText uses label if not set
//     insertText: insertText != label
//         ? insertText
//         : null, // insertText uses label if not set
//     insertTextFormat: insertTextFormat != InsertTextFormat.PlainText
//         ? insertTextFormat
//         : null, // Defaults to PlainText if not supplied
//     insertTextMode: supportsAsIsInsertMode && isMultilineCompletion
//         ? InsertTextMode.asIs
//         : null,
//     textEdit: supportsInsertReplace && insertLength != replacementLength
//         ? Either2<TextEdit, InsertReplaceEdit>.t2(
//             InsertReplaceEdit(
//               insert: toRange(lineInfo, replacementOffset, insertLength),
//               replace: toRange(lineInfo, replacementOffset, replacementLength),
//               newText: insertText,
//             ),
//           )
//         : Either2<TextEdit, InsertReplaceEdit>.t1(
//             TextEdit(
//               range: toRange(lineInfo, replacementOffset, replacementLength),
//               newText: insertText,
//             ),
//           ),
//   );
// }

lsp.Diagnostic toDiagnostic(
  HTSourceAnalysisResult result,
  HTAnalysisError error, {
  // Set<lsp.DiagnosticTag> supportedTags,
  ErrorSeverity errorSeverity,
}) {
  // Default to the error's severity if none is specified.
  errorSeverity ??= error.severity;

  List<lsp.DiagnosticRelatedInformation> relatedInformation;
  if (error.contextMessages.isNotEmpty) {
    relatedInformation = error.contextMessages
        .map((message) => toDiagnosticRelatedInformation(result, message))
        .toList();
  }

  var message = error.message;
  if (error.correction != null) {
    message = '$message\n${error.correction}';
  }

  return lsp.Diagnostic(
    range: toRange(result.lineInfo, error.offset, error.length),
    severity: toDiagnosticSeverity(errorSeverity),
    code: error.name.toLowerCase(),
    source: languageSourceName,
    message: message,
    // tags: getDiagnosticTags(supportedTags, error),
    relatedInformation: relatedInformation,
  );
}

lsp.DiagnosticRelatedInformation toDiagnosticRelatedInformation(
    HTSourceAnalysisResult result, HTDiagnosticMessage message) {
  var file = message.filename;
  var lineInfo = result.lineInfo;
  return lsp.DiagnosticRelatedInformation(
      location: lsp.Location(
        uri: Uri.file(file).toString(),
        range: toRange(
          lineInfo,
          message.offset,
          message.length,
        ),
      ),
      message: message.message);
}

lsp.DiagnosticSeverity toDiagnosticSeverity(ErrorSeverity severity) {
  if (severity == ErrorSeverity.error) {
    return lsp.DiagnosticSeverity.Error;
  } else if (severity == ErrorSeverity.warning) {
    return lsp.DiagnosticSeverity.Warning;
  } else if (severity == ErrorSeverity.info) {
    return lsp.DiagnosticSeverity.Information;
  }
  // Note: LSP also supports "Hint", but they won't render in things like the
  // VS Code errors list as they're apparently intended to communicate
  // non-visible diagnostics back (for example, if you wanted to grey out
  // unreachable code without producing an item in the error list).
  else {
    throw 'Unknown AnalysisErrorSeverity: $severity';
  }
}

lsp.Element toElement(LineInfo lineInfo, Element element) => lsp.Element(
      range: element.location != null
          ? toRange(lineInfo, element.location.offset, element.location.length)
          : null,
      name: toElementName(element),
      kind: element.kind.name,
      parameters: element.parameters,
      typeParameters: element.typeParameters,
      returnType: element.returnType,
    );

String toElementName(Element element) {
  return element.name != null && element.name != ''
      ? element.name
      : (element.kind == ElementKind.EXTENSION
          ? '<unnamed extension>'
          : '<unnamed>');
}

// FoldingRange toFoldingRange(
//     server.LineInfo lineInfo, server.FoldingRegion region) {
//   final range = toRange(lineInfo, region.offset, region.length);
//   return FoldingRange(
//       startLine: range.start.line,
//       startCharacter: range.start.character,
//       endLine: range.end.line,
//       endCharacter: range.end.character,
//       kind: toFoldingRangeKind(region.kind));
// }

// FoldingRangeKind toFoldingRangeKind(server.FoldingKind kind) {
//   switch (kind) {
//     case server.FoldingKind.COMMENT:
//     case server.FoldingKind.DOCUMENTATION_COMMENT:
//     case server.FoldingKind.FILE_HEADER:
//       return FoldingRangeKind.Comment;
//     case server.FoldingKind.DIRECTIVES:
//       return FoldingRangeKind.Imports;
//     default:
//       // null (actually undefined in LSP, the toJson() takes care of that) is
//       // valid, and actually the value used for the majority of folds
//       // (class/functions/etc.).
//       return null;
//   }
// }

List<lsp.DocumentHighlight> toHighlights(
    LineInfo lineInfo, Occurrences occurrences) {
  return occurrences.offsets
      .map((offset) => lsp.DocumentHighlight(
          range: toRange(lineInfo, offset, occurrences.length)))
      .toList();
}

lsp.Location toLocation(Location location, LineInfo lineInfo) => lsp.Location(
      uri: Uri.file(location.file).toString(),
      range: toRange(
        lineInfo,
        location.offset,
        location.length,
      ),
    );

ErrorOr<int> toOffset(
  LineInfo lineInfo,
  lsp.Position pos, {
  failureIsCritial = false,
}) {
  // line is zero-based so cannot equal lineCount
  if (pos.line >= lineInfo.lineCount) {
    return ErrorOr<int>.error(lsp.ResponseError(
        code: failureIsCritial
            ? ServerErrorCodes.ClientServerInconsistentState
            : ServerErrorCodes.InvalidFileLineCol,
        message: 'Invalid line number',
        data: pos.line.toString()));
  }
  // TODO(dantup): Is there any way to validate the character? We could ensure
  // it's less than the offset of the next line, but that would only work for
  // all lines except the last one.
  return ErrorOr<int>.success(
      lineInfo.getOffsetOfLine(pos.line) + pos.character);
}

lsp.Outline toOutline(LineInfo lineInfo, Outline outline) => lsp.Outline(
      element: toElement(lineInfo, outline.element),
      range: toRange(lineInfo, outline.offset, outline.length),
      codeRange: toRange(lineInfo, outline.codeOffset, outline.codeLength),
      children: outline.children != null
          ? outline.children.map((c) => toOutline(lineInfo, c)).toList()
          : null,
    );

lsp.Position toPosition(CharacterLocation location) {
  // LSP is zero-based, but analysis server is 1-based.
  return lsp.Position(line: location.line - 1, character: location.column - 1);
}

lsp.Range toRange(LineInfo lineInfo, int offset, int length) {
  final start = lineInfo.getLocation(offset);
  final end = lineInfo.getLocation(offset + length);

  return lsp.Range(
    start: toPosition(start),
    end: toPosition(end),
  );
}

// lsp.SignatureHelp toSignatureHelp(Set<MarkupKind> preferredFormats,
//     server.AnalysisGetSignatureResult signature) {
//   // For now, we only support returning one (though we may wish to use named
//   // args. etc. to provide one for each possible "next" option when the cursor
//   // is at the end ready to provide another argument).

//   /// Gets the label for an individual parameter in the form
//   ///     String s = 'foo'
//   String getParamLabel(server.ParameterInfo p) {
//     final def = p.defaultValue != null ? ' = ${p.defaultValue}' : '';
//     final prefix =
//         p.kind == server.ParameterKind.REQUIRED_NAMED ? 'required ' : '';
//     return '$prefix${p.type} ${p.name}$def';
//   }

//   /// Gets the full signature label in the form
//   ///     foo(String s, int i, bool a = true)
//   String getSignatureLabel(server.AnalysisGetSignatureResult resp) {
//     final positionalRequired = signature.parameters
//         .where((p) => p.kind == server.ParameterKind.REQUIRED_POSITIONAL)
//         .toList();
//     final positionalOptional = signature.parameters
//         .where((p) => p.kind == server.ParameterKind.OPTIONAL_POSITIONAL)
//         .toList();
//     final named = signature.parameters
//         .where((p) =>
//             p.kind == server.ParameterKind.OPTIONAL_NAMED ||
//             p.kind == server.ParameterKind.REQUIRED_NAMED)
//         .toList();
//     final params = [];
//     if (positionalRequired.isNotEmpty) {
//       params.add(positionalRequired.map(getParamLabel).join(', '));
//     }
//     if (positionalOptional.isNotEmpty) {
//       params.add('[' + positionalOptional.map(getParamLabel).join(', ') + ']');
//     }
//     if (named.isNotEmpty) {
//       params.add('{' + named.map(getParamLabel).join(', ') + '}');
//     }
//     return '${resp.name}(${params.join(", ")})';
//   }

//   ParameterInformation toParameterInfo(server.ParameterInfo param) {
//     // LSP 3.14.0 supports providing label offsets (to avoid clients having
//     // to guess based on substrings). We should check the
//     // signatureHelp.signatureInformation.parameterInformation.labelOffsetSupport
//     // capability when deciding to send that.
//     return ParameterInformation(label: getParamLabel(param));
//   }

//   final cleanDoc = cleanDartdoc(signature.dartdoc);

//   return SignatureHelp(
//     signatures: [
//       SignatureInformation(
//         label: getSignatureLabel(signature),
//         documentation: asStringOrMarkupContent(preferredFormats, cleanDoc),
//         parameters: signature.parameters.map(toParameterInfo).toList(),
//       ),
//     ],
//     activeSignature: 0, // activeSignature
//     // TODO(dantup): The LSP spec says this value will default to 0 if it's
//     // not supplied or outside of the value range. However, setting -1 results
//     // in no parameters being selected in VS Code, whereas null/0 will select the first.
//     // We'd like for none to be selected (since we don't support this yet) so
//     // we send -1. I've made a request for LSP to support not selecting a parameter
//     // (because you could also be on param 5 of an invalid call to a function
//     // taking only 3 arguments) here:
//     // https://github.com/Microsoft/language-server-protocol/issues/456#issuecomment-452318297
//     activeParameter: -1, // activeParameter
//   );
// }

lsp.SnippetTextEdit toSnippetTextEdit(
    LspClientCapabilities capabilities,
    LineInfo lineInfo,
    SourceEdit edit,
    int selectionOffsetRelative,
    int selectionLength) {
  assert(selectionOffsetRelative != null);
  return lsp.SnippetTextEdit(
    insertTextFormat: lsp.InsertTextFormat.Snippet,
    range: toRange(lineInfo, edit.offset, edit.length),
    newText: buildSnippetStringWithTabStops(
        edit.replacement, [selectionOffsetRelative, selectionLength ?? 0]),
  );
}

ErrorOr<SourceRange> toSourceRange(LineInfo lineInfo, lsp.Range range) {
  if (range == null) {
    return success(null);
  }

  // If there is a range, convert to offsets because that's what
  // the tokens are computed using initially.
  final start = toOffset(lineInfo, range.start);
  final end = toOffset(lineInfo, range.end);
  if (start?.isError ?? false) {
    return failure(start);
  }
  if (end?.isError ?? false) {
    return failure(end);
  }

  final startOffset = start?.result;
  final endOffset = end?.result;

  return success(SourceRange(startOffset, endOffset - startOffset));
}

lsp.TextDocumentEdit toTextDocumentEdit(
    LspClientCapabilities capabilities, FileEditInformation edit) {
  return lsp.TextDocumentEdit(
      textDocument: edit.doc,
      edits: edit.edits
          .map((e) => toTextDocumentEditEdit(capabilities, edit.lineInfo, e,
              selectionOffsetRelative: edit.selectionOffsetRelative,
              selectionLength: edit.selectionLength))
          .toList());
}

Either3<lsp.SnippetTextEdit, lsp.AnnotatedTextEdit, lsp.TextEdit>
    toTextDocumentEditEdit(
  LspClientCapabilities capabilities,
  LineInfo lineInfo,
  SourceEdit edit, {
  int selectionOffsetRelative,
  int selectionLength,
}) {
  if (!capabilities.experimentalSnippetTextEdit ||
      selectionOffsetRelative == null) {
    return Either3<lsp.SnippetTextEdit, lsp.AnnotatedTextEdit, lsp.TextEdit>.t3(
        toTextEdit(lineInfo, edit));
  }
  return Either3<lsp.SnippetTextEdit, lsp.AnnotatedTextEdit, lsp.TextEdit>.t1(
      toSnippetTextEdit(capabilities, lineInfo, edit, selectionOffsetRelative,
          selectionLength));
}

lsp.TextEdit toTextEdit(LineInfo lineInfo, SourceEdit edit) {
  return lsp.TextEdit(
    range: toRange(lineInfo, edit.offset, edit.length),
    newText: edit.replacement,
  );
}

lsp.WorkspaceEdit toWorkspaceEdit(
  LspClientCapabilities capabilities,
  List<FileEditInformation> edits,
) {
  final supportsDocumentChanges = capabilities.documentChanges;
  if (supportsDocumentChanges) {
    final supportsCreate = capabilities.createResourceOperations;
    final changes = <
        Either4<lsp.TextDocumentEdit, lsp.CreateFile, lsp.RenameFile,
            lsp.DeleteFile>>[];

    // Convert each SourceEdit to either a TextDocumentEdit or a
    // CreateFile + a TextDocumentEdit depending on whether it's a new
    // file.
    for (final edit in edits) {
      if (supportsCreate && edit.newFile) {
        final create = lsp.CreateFile(uri: edit.doc.uri);
        final createUnion = Either4<lsp.TextDocumentEdit, lsp.CreateFile,
            lsp.RenameFile, lsp.DeleteFile>.t2(create);
        changes.add(createUnion);
      }

      final textDocEdit = toTextDocumentEdit(capabilities, edit);
      final textDocEditUnion = Either4<lsp.TextDocumentEdit, lsp.CreateFile,
          lsp.RenameFile, lsp.DeleteFile>.t1(textDocEdit);
      changes.add(textDocEditUnion);
    }

    return lsp.WorkspaceEdit(
        documentChanges: Either2<
            List<lsp.TextDocumentEdit>,
            List<
                Either4<lsp.TextDocumentEdit, lsp.CreateFile, lsp.RenameFile,
                    lsp.DeleteFile>>>.t2(changes));
  } else {
    return lsp.WorkspaceEdit(changes: toWorkspaceEditChanges(edits));
  }
}

Map<String, List<lsp.TextEdit>> toWorkspaceEditChanges(
    List<FileEditInformation> edits) {
  MapEntry<String, List<lsp.TextEdit>> createEdit(FileEditInformation file) {
    final edits =
        file.edits.map((edit) => toTextEdit(file.lineInfo, edit)).toList();
    return MapEntry(file.doc.uri, edits);
  }

  return Map<String, List<lsp.TextEdit>>.fromEntries(edits.map(createEdit));
}

lsp.MarkupContent _asMarkup(
    Set<lsp.MarkupKind> preferredFormats, String content) {
  // It's not valid to call this function with a null format, as null formats
  // do not support MarkupContent. [asStringOrMarkupContent] is probably the
  // better choice.
  assert(preferredFormats != null);

  if (content == null) {
    return null;
  }

  if (preferredFormats.isEmpty) {
    preferredFormats.add(lsp.MarkupKind.Markdown);
  }

  final supportsMarkdown = preferredFormats.contains(lsp.MarkupKind.Markdown);
  final supportsPlain = preferredFormats.contains(lsp.MarkupKind.PlainText);
  // Since our PlainText version is actually just Markdown, only advertise it
  // as PlainText if the client explicitly supports PlainText and not Markdown.
  final format = supportsPlain && !supportsMarkdown
      ? lsp.MarkupKind.PlainText
      : lsp.MarkupKind.Markdown;

  return lsp.MarkupContent(kind: format, value: content);
}

// Pair<String, lsp.InsertTextFormat> _buildInsertText({
//   @required bool supportsSnippets,
//   @required bool includeCommitCharacters,
//   @required bool completeFunctionCalls,
//   @required bool isCallable,
//   @required bool isInvocation,
//   @required String defaultArgumentListString,
//   @required List<int> defaultArgumentListTextRanges,
//   @required String completion,
//   @required int selectionOffset,
//   @required int selectionLength,
// }) {
//   var insertText = completion;
//   var insertTextFormat = lsp.InsertTextFormat.PlainText;

//   // SuggestionBuilder already does the equiv of completeFunctionCalls for
//   // some methods (for example Flutter's setState). If the completion already
//   // includes any `(` then disable our own insertion as the special-cased code
//   // will likely provide better code.
//   if (completion.contains('(')) {
//     completeFunctionCalls = false;
//   }

//   // If the client supports snippets, we can support completeFunctionCalls or
//   // setting a selection.
//   if (supportsSnippets) {
//     // completeFunctionCalls should only work if commit characters are disabled
//     // otherwise the editor may insert parens that we're also inserting.
//     if (!includeCommitCharacters &&
//         completeFunctionCalls &&
//         isCallable &&
//         isInvocation) {
//       insertTextFormat = lsp.InsertTextFormat.Snippet;
//       final hasRequiredParameters =
//           (defaultArgumentListTextRanges?.length ?? 0) > 0;
//       final functionCallSuffix = hasRequiredParameters
//           ? buildSnippetStringWithTabStops(
//               defaultArgumentListString,
//               defaultArgumentListTextRanges,
//             )
//           : '\${0:}'; // No required params still gets a tabstop in the parens.
//       insertText += '($functionCallSuffix)';
//     } else if (selectionOffset != 0 &&
//         // We don't need a tabstop if the selection is the end of the string.
//         selectionOffset != completion.length) {
//       insertTextFormat = lsp.InsertTextFormat.Snippet;
//       insertText = buildSnippetStringWithTabStops(
//         completion,
//         [selectionOffset, selectionLength],
//       );
//     }
//   }

//   return Pair(insertText, insertTextFormat);
// }
