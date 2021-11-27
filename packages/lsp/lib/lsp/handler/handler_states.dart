// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';

import '../../protocol/protocol_generated.dart';
import '../../protocol/protocol_special.dart';
import '../constants.dart';
import '../lsp_analysis_server.dart';
import 'handlers.dart';
import 'handler_initialize.dart';
import 'handler_initialized.dart';
import 'handler_shutdown.dart';
import 'handler_exit.dart';
import 'handler_text_document_changes.dart';
import 'handler_change_workspace_folders.dart';
import 'handler_document_highlights.dart';

/// The server moves to this state when a critical unrecoverrable error (for
/// example, inconsistent document state between server/client) occurs and will
/// reject all messages.
class FailureStateMessageHandler extends ServerStateMessageHandler {
  FailureStateMessageHandler(LspAnalysisServer server) : super(server);

  @override
  FutureOr<ErrorOr<Object>> handleUnknownMessage(IncomingMessage message) {
    return error(
        ErrorCodes.InternalError,
        'An unrecoverable error occurred and the server cannot process messages',
        null);
  }
}

class InitializedStateMessageHandler extends ServerStateMessageHandler {
  InitializedStateMessageHandler(
    LspAnalysisServer server,
  ) : super(server) {
    reject(Method.initialize, ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');
    reject(Method.initialized, ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');
    registerHandler(ShutdownMessageHandler(server));
    registerHandler(ExitMessageHandler(server));
    registerHandler(
      TextDocumentOpenHandler(server),
    );
    registerHandler(TextDocumentChangeHandler(server));
    registerHandler(
      TextDocumentCloseHandler(server),
    );
    // registerHandler(HoverHandler(server));
    // registerHandler(CompletionHandler(
    //   server,
    //   server.initializationOptions.suggestFromUnimportedLibraries,
    // ));
    // registerHandler(CompletionResolveHandler(server));
    // registerHandler(SignatureHelpHandler(server));
    // registerHandler(DefinitionHandler(server));
    // registerHandler(SuperHandler(server));
    // registerHandler(ReferencesHandler(server));
    // registerHandler(ImplementationHandler(server));
    // registerHandler(FormattingHandler(server));
    // registerHandler(FormatOnTypeHandler(server));
    // registerHandler(FormatRangeHandler(server));
    registerHandler(DocumentHighlightsHandler(server));
    // registerHandler(DocumentSymbolHandler(server));
    // registerHandler(CodeActionHandler(server));
    // registerHandler(ExecuteCommandHandler(server));
    registerHandler(
      ChangeWorkspaceFoldersHandler(
        server,
        !server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles,
      ),
    );
    // registerHandler(PrepareRenameHandler(server));
    // registerHandler(RenameHandler(server));
    // registerHandler(FoldingHandler(server));
    // registerHandler(DiagnosticServerHandler(server));
    // registerHandler(WorkspaceSymbolHandler(server));
    // registerHandler(WorkspaceDidChangeConfigurationMessageHandler(server));
    // registerHandler(ReanalyzeHandler(server));
    // registerHandler(WillRenameFilesHandler(server));
    // registerHandler(SemanticTokensFullHandler(server));
    // registerHandler(SemanticTokensRangeHandler(server));
  }
}

class InitializingStateMessageHandler extends ServerStateMessageHandler {
  InitializingStateMessageHandler(
    LspAnalysisServer server,
    List<String> openWorkspacePaths,
  ) : super(server) {
    reject(Method.initialize, ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');
    registerHandler(ShutdownMessageHandler(server));
    registerHandler(ExitMessageHandler(server));
    registerHandler(IntializedMessageHandler(
      server,
      openWorkspacePaths,
    ));
  }

  @override
  ErrorOr<void> handleUnknownMessage(IncomingMessage message) {
    // Silently drop non-requests.
    if (message is! RequestMessage) {
      // server.instrumentationService
      //     .logInfo('Ignoring ${message.method} message while initializing');
      return success();
    }
    return error(
        ErrorCodes.ServerNotInitialized,
        'Unable to handle ${message.method} before the server is initialized '
        'and the client has sent the initialized notification');
  }
}

class ShuttingDownStateMessageHandler extends ServerStateMessageHandler {
  ShuttingDownStateMessageHandler(LspAnalysisServer server) : super(server) {
    registerHandler(ExitMessageHandler(server, clientDidCallShutdown: true));
  }

  @override
  FutureOr<ErrorOr<Object>> handleUnknownMessage(IncomingMessage message) {
    // Silently drop non-requests.
    if (message is! RequestMessage) {
      // server.instrumentationService
      //     .logInfo('Ignoring ${message.method} message while shutting down');
      return success();
    }
    return error(ErrorCodes.InvalidRequest,
        'Unable to handle ${message.method} after shutdown request');
  }
}

class UninitializedStateMessageHandler extends ServerStateMessageHandler {
  UninitializedStateMessageHandler(LspAnalysisServer server) : super(server) {
    registerHandler(ShutdownMessageHandler(server));
    registerHandler(ExitMessageHandler(server));
    registerHandler(InitializeMessageHandler(server));
  }

  @override
  FutureOr<ErrorOr<Object>> handleUnknownMessage(IncomingMessage message) {
    // Silently drop non-requests.
    if (message is! RequestMessage) {
      // server.instrumentationService
      //     .logInfo('Ignoring ${message.method} message while uninitialized');
      return success();
    }
    return error(ErrorCodes.ServerNotInitialized,
        'Unable to handle ${message.method} before client has sent initialize request');
  }
}
