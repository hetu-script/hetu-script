// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:hetu_script/hetu_script.dart';

// import 'package:analysis_server/plugin/protocol/protocol_dart.dart';
// import 'package:analysis_server/protocol/protocol_generated.dart';
// import 'package:analysis_server/src/services/correction/fix.dart';
// import 'package:analysis_server/src/services/search/search_engine.dart'
//     as engine;
// import 'package:analysis_server/src/utilities/extensions/element.dart';
// import 'package:analyzer/dart/analysis/results.dart' as engine;
// import 'package:analyzer/dart/ast/ast.dart' as engine;
// import 'package:analyzer/dart/element/element.dart' as engine;
// import 'package:analyzer/dart/element/type.dart';
// import 'package:analyzer/diagnostic/diagnostic.dart' as engine;
// import 'package:analyzer/error/error.dart' as engine;
// import 'package:analyzer/exception/exception.dart';
// import 'package:analyzer/source/error_processor.dart';
// import 'package:analyzer/src/generated/source.dart' as engine;
// import 'package:analyzer_plugin/protocol/protocol_common.dart';

import 'protocol_hetu.dart';
// export 'package:analysis_server/protocol/protocol.dart';
import 'protocol_generated2.dart';
import 'protocol_common.dart';

/// Adds [edit] to the file containing the given [element].
void doSourceChange_addElementEdit(
    SourceChange change, HTDeclaration decl, SourceEdit edit) {
  doSourceChange_addSourceEdit(change, decl.source!, edit);
}

/// Adds [edit] for the given [source] to the [change].
void doSourceChange_addSourceEdit(
    SourceChange change, HTSource source, SourceEdit edit,
    {bool isNewFile = false}) {
  var file = source.fullName;
  change.addEdit(file, isNewFile ? -1 : 0, edit);
}

/// Create a Location based on an [engine.Element].
Location? newLocation_fromDeclaration(HTDeclaration? decl) {
  if (decl == null || decl.source == null) {
    return null;
  }
  final offset = decl.idRange.offset;
  final length = decl.idRange.length;
  // if (decl is HTModuleAnalysisResult ||
  //     (decl is HTLibraryAnalysisResult && offset < 0)) {
  //   offset = 0;
  //   length = 0;
  // }
  // var unitElement = _getUnitElement(decl);
  final source = decl.source!;
  final range = SourceRange(offset, length);
  return _locationForArgs(source, range);
}

/// Create a Location based on an [engine.SearchMatch].
// Location newLocation_fromMatch(engine.SearchMatch match) {
//   var unitElement = _getUnitElement(match.element);
//   return _locationForArgs(unitElement, match.sourceRange);
// }

/// Create a Location based on an [engine.AstNode].
Location newLocation_fromNode(AstNode node) {
  var range = SourceRange(node.offset, node.length);
  return _locationForArgs(node.source!, range);
}

/// Create a Location based on an [engine.CompilationUnit].
Location newLocation_fromModule(HTModule module, SourceRange range) {
  return _locationForArgs(module.source!, range);
}

/// Construct based on an element from the analyzer engine.
OverriddenMember newOverriddenMember_fromEngine(HTDeclaration member) {
  var element = convertDeclaration(member);
  var className = member.classId!;
  return OverriddenMember(element, className);
}

/// Construct based on a value from the search engine.
// SearchResult newSearchResult_fromMatch(engine.SearchMatch match) {
//   var kind = newSearchResultKind_fromEngine(match.kind);
//   var location = newLocation_fromMatch(match);
//   var path = _computePath(match.element);
//   return SearchResult(location, kind, !match.isResolved, path);
// }

/// Construct based on a value from the search engine.
// SearchResultKind newSearchResultKind_fromEngine(engine.MatchKind kind) {
//   if (kind == engine.MatchKind.DECLARATION) {
//     return SearchResultKind.DECLARATION;
//   }
//   if (kind == engine.MatchKind.READ) {
//     return SearchResultKind.READ;
//   }
//   if (kind == engine.MatchKind.READ_WRITE) {
//     return SearchResultKind.READ_WRITE;
//   }
//   if (kind == engine.MatchKind.WRITE) {
//     return SearchResultKind.WRITE;
//   }
//   if (kind == engine.MatchKind.INVOCATION) {
//     return SearchResultKind.INVOCATION;
//   }
//   if (kind == engine.MatchKind.REFERENCE) {
//     return SearchResultKind.REFERENCE;
//   }
//   return SearchResultKind.UNKNOWN;
// }

/// Construct based on a SourceRange.
SourceEdit newSourceEdit_range(SourceRange range, String replacement,
    {String? id}) {
  return SourceEdit(range.offset, range.length, replacement, id: id);
}

// List<Element> _computePath(engine.Element element) {
//   var path = <Element>[];

//   if (element is engine.PrefixElement) {
//     element = element.enclosingElement.definingCompilationUnit;
//   }

//   for (var e in element.withAncestors) {
//     path.add(convertElement(e));
//   }
//   return path;
// }

// engine.CompilationUnitElement _getUnitElement(engine.Element element) {
//   if (element is engine.CompilationUnitElement) {
//     return element;
//   }

//   var enclosingElement = element.enclosingElement;
//   if (enclosingElement is engine.LibraryElement) {
//     element = enclosingElement;
//   }

//   if (element is engine.LibraryElement) {
//     return element.definingCompilationUnit;
//   }

//   for (var e in element.withAncestors) {
//     if (e is engine.CompilationUnitElement) {
//       return e;
//     }
//   }

//   throw StateError('No unit: $element');
// }

/// Creates a new [Location].
Location _locationForArgs(HTSource source, SourceRange range) {
  var startLine = 0;
  var startColumn = 0;
  var endLine = 0;
  var endColumn = 0;
  var lineInfo = source.lineInfo;
  var startLocation = lineInfo.getLocation(range.offset);
  startLine = startLocation.line;
  startColumn = startLocation.column;

  var endLocation = lineInfo.getLocation(range.end);
  endLine = endLocation.line;
  endColumn = endLocation.column;
  return Location(source.fullName, range.offset, range.length, startLine,
      startColumn, endLine, endColumn);
}
