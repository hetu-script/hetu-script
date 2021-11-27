// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import '../../protocol/protocol_generated.dart';
import '../../protocol/protocol_special.dart';
import '../constants.dart';
import '../lsp_analysis_server.dart';
import '../mapping.dart';
import '../source_edits.dart';
import 'handlers.dart';

class TextDocumentChangeHandler
    extends MessageHandler<DidChangeTextDocumentParams, void> {
  TextDocumentChangeHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_didChange;

  @override
  LspJsonHandler<DidChangeTextDocumentParams> get jsonHandler =>
      DidChangeTextDocumentParams.jsonHandler;

  @override
  ErrorOr<void> handle(
      DidChangeTextDocumentParams params, CancellationToken token) {
    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) => _changeFile(path, params));
  }

  ErrorOr<void> _changeFile(String path, DidChangeTextDocumentParams params) {
    String oldContents;
    if (server.contextManager.hasResource(path)) {
      final source = server.contextManager.getResource(path);
      if (source != null) {
        oldContents = source.content;
      }
    }
    // If we didn't have the file contents, the server and client are out of sync
    // and this is a serious failure.
    if (oldContents == null) {
      return error(
        ServerErrorCodes.ClientServerInconsistentState,
        'Unable to edit document because the file was not previously opened: $path',
        null,
      );
    }
    final newContents = applyAndConvertEditsToServer(
        oldContents, params.contentChanges,
        failureIsCritical: true);

    server.logger.log('document changed [$path]');

    return newContents.mapResult((result) {
      server.documentVersions[path] = params.textDocument;
      server.onOverlayUpdated(path, result.last, newContent: result.first);
      return success();
    });
  }
}

class TextDocumentCloseHandler
    extends MessageHandler<DidCloseTextDocumentParams, void> {
  TextDocumentCloseHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.textDocument_didClose;

  @override
  LspJsonHandler<DidCloseTextDocumentParams> get jsonHandler =>
      DidCloseTextDocumentParams.jsonHandler;

  @override
  ErrorOr<void> handle(
      DidCloseTextDocumentParams params, CancellationToken token) {
    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) {
      server.removeOpenFile(path);
      server.documentVersions.remove(path);
      server.onOverlayDestroyed(path);
      server.logger.log('document closed [$path]');
      return success();
    });
  }
}

class TextDocumentOpenHandler
    extends MessageHandler<DidOpenTextDocumentParams, void> {
  TextDocumentOpenHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.textDocument_didOpen;

  @override
  LspJsonHandler<DidOpenTextDocumentParams> get jsonHandler =>
      DidOpenTextDocumentParams.jsonHandler;

  @override
  ErrorOr<void> handle(
      DidOpenTextDocumentParams params, CancellationToken token) {
    final doc = params.textDocument;
    final path = pathOfDocItem(doc);
    server.logger.log('document opened [$path]');
    return path.mapResult((path) {
      // We don't get a OptionalVersionedTextDocumentIdentifier with a didOpen but we
      // do get the necessary info to create one.
      server.documentVersions[path] = VersionedTextDocumentIdentifier(
        version: params.textDocument.version,
        uri: params.textDocument.uri,
      );
      server.onOverlayCreated(path, doc.text);
      server.addOpenFile(path);
      return success();
    });
  }
}
