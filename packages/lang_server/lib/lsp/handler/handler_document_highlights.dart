// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import '../../protocol/protocol_generated.dart';
import '../../protocol/protocol_special.dart';
import '../../analyzer/occurrences_collector.dart';
import '../lsp_analysis_server.dart';
import '../mapping.dart';
import 'handlers.dart';

class DocumentHighlightsHandler extends MessageHandler<
    TextDocumentPositionParams, List<DocumentHighlight>> {
  DocumentHighlightsHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_documentHighlight;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  Future<ErrorOr<List<DocumentHighlight>>> handle(
      TextDocumentPositionParams params, CancellationToken token) async {
    if (!isHetuDocument(params.textDocument)) {
      return success(const []);
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final result = path.mapResult(requireParseResult);
    final offset = result.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((requestedOffset) {
      final collector = OccurrencesCollector(result.result.nodes);

      // Find an occurrence that has an instance that spans the position.
      for (final occurrence in collector.allOccurrences) {
        bool spansRequestedPosition(int offset) {
          return offset <= requestedOffset &&
              offset + occurrence.length >= requestedOffset;
        }

        if (occurrence.offsets.any(spansRequestedPosition)) {
          return success(toHighlights(result.result.lineInfo, occurrence));
        }
      }

      // No matches.
      return success(null);
    });
  }
}
