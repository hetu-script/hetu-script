// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:hetu_script/hetu_script.dart';

import '../protocol/protocol_hetu.dart';
import '../protocol/protocol_common.dart';

class OccurrencesCollector {
  final Map<Element, Occurrences> elementOccurrences = <Element, Occurrences>{};

  OccurrencesCollector(List<AstNode> nodes) {
    final visitor = _OccurrencesComputerVisitor();
    for (final node in nodes) {
      node.accept(visitor);
    }
    visitor.declOffsets.forEach((decl, offsets) {
      final length = decl.idRange.length;
      final lspElement = convertDeclaration(decl);
      final occurrences = Occurrences(lspElement, offsets, length);
      addOccurrences(occurrences);
    });
  }

  List<Occurrences> get allOccurrences {
    return elementOccurrences.values.toList();
  }

  void addOccurrences(Occurrences occurrences) {
    var element = occurrences.element;
    var existing = elementOccurrences[element];
    if (existing != null) {
      var offsets = _merge(existing.offsets, occurrences.offsets);
      occurrences = Occurrences(element, offsets, existing.length);
    }
    elementOccurrences[element] = occurrences;
  }

  static List<int> _merge(List<int> a, List<int> b) {
    return <int>[...a, ...b];
  }
}

class _OccurrencesComputerVisitor extends RecursiveAstVisitor<void> {
  final Map<HTDeclaration, List<int>> declOffsets =
      <HTDeclaration, List<int>>{};

  @override
  void visitSymbolExpr(SymbolExpr expr) {
    final decl = expr.declaration;
    if (decl != null) {
      var offsets = declOffsets[decl];
      if (offsets == null) {
        offsets = <int>[];
        declOffsets[decl] = offsets;
      }
      offsets.add(expr.offset);
    }
  }
}
