// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/parser.dart';

import '../../protocol/protocol_generated.dart';
import '../../protocol/protocol_special.dart';
import '../../computer/computer_outline.dart';
import '../capability/client_capabilities.dart';
import 'handlers.dart';
import '../lsp_analysis_server.dart';
import '../mapping.dart';
import '../../protocol/protocol_common.dart' show Outline;
// import 'package:analyzer/dart/analysis/results.dart';

class DocumentSymbolHandler extends MessageHandler<DocumentSymbolParams,
    Either2<List<DocumentSymbol>, List<SymbolInformation>>> {
  DocumentSymbolHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_documentSymbol;

  @override
  LspJsonHandler<DocumentSymbolParams> get jsonHandler =>
      DocumentSymbolParams.jsonHandler;

  @override
  Future<ErrorOr<Either2<List<DocumentSymbol>, List<SymbolInformation>>>>
      handle(DocumentSymbolParams params, CancellationToken token) async {
    if (!isHetuDocument(params.textDocument)) {
      return success(
        Either2<List<DocumentSymbol>, List<SymbolInformation>>.t2([]),
      );
    }

    final path = pathOfDoc(params.textDocument);
    final unit = path.mapResult(requireParseResult);
    return unit.mapResult(
        (unit) => _getSymbols(server.clientCapabilities, path.result, unit));
  }

  DocumentSymbol _asDocumentSymbol(
    Set<SymbolKind> supportedKinds,
    LineInfo lineInfo,
    Outline outline,
  ) {
    return DocumentSymbol(
      name: toElementName(outline.element),
      detail: outline.element.parameters,
      kind: elementKindToSymbolKind(supportedKinds, outline.element.kind),
      deprecated: outline.element.isDeprecated,
      range: toRange(lineInfo, outline.codeOffset, outline.codeLength),
      selectionRange: toRange(lineInfo, outline.element.location.offset,
          outline.element.location.length),
      children: outline.children
          ?.map((child) => _asDocumentSymbol(supportedKinds, lineInfo, child))
          ?.toList(),
    );
  }

  SymbolInformation _asSymbolInformation(
    String containerName,
    Set<SymbolKind> supportedKinds,
    String documentUri,
    LineInfo lineInfo,
    Outline outline,
  ) {
    return SymbolInformation(
      name: toElementName(outline.element),
      kind: elementKindToSymbolKind(supportedKinds, outline.element.kind),
      deprecated: outline.element.isDeprecated,
      location: Location(
        uri: documentUri,
        range: toRange(lineInfo, outline.element.location.offset,
            outline.element.location.length),
      ),
      containerName: containerName,
    );
  }

  ErrorOr<Either2<List<DocumentSymbol>, List<SymbolInformation>>> _getSymbols(
    LspClientCapabilities capabilities,
    String path,
    HTModuleParseResult unit,
  ) {
    final computer = HetuModuleOutlineComputer(unit);
    final outline = computer.compute();

    if (capabilities.hierarchicalSymbols) {
      // Return a tree of DocumentSymbol only if the client shows explicit support
      // for it.
      return success(
        Either2<List<DocumentSymbol>, List<SymbolInformation>>.t1(
          outline?.children
              ?.map((child) => _asDocumentSymbol(
                  capabilities.documentSymbolKinds, unit.lineInfo, child))
              ?.toList(),
        ),
      );
    } else {
      // Otherwise, we need to use the original flat SymbolInformation.
      final allSymbols = <SymbolInformation>[];
      final documentUri = Uri.file(path).toString();

      // Adds a symbol and it's children recursively, supplying the parent
      // name as required by SymbolInformation.
      void addSymbol(Outline outline, {String parentName}) {
        allSymbols.add(_asSymbolInformation(
          parentName,
          capabilities.documentSymbolKinds,
          documentUri,
          unit.lineInfo,
          outline,
        ));
        outline.children?.forEach(
          (c) => addSymbol(c, parentName: outline.element.name),
        );
      }

      outline?.children?.forEach(addSymbol);

      return success(
        Either2<List<DocumentSymbol>, List<SymbolInformation>>.t2(allSymbols),
      );
    }
  }
}
