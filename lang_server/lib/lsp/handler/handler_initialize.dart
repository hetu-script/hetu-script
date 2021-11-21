// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// import 'dart:io';

import '../../protocol/protocol_generated.dart';
import '../../protocol/protocol_special.dart';
import '../lsp_analysis_server.dart';
import 'handler_states.dart';
import 'handlers.dart';
import '../../common/constants.dart';

class InitializeMessageHandler
    extends MessageHandler<InitializeParams, InitializeResult> {
  InitializeMessageHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.initialize;

  @override
  LspJsonHandler<InitializeParams> get jsonHandler =>
      InitializeParams.jsonHandler;

  @override
  ErrorOr<InitializeResult> handle(
      InitializeParams params, CancellationToken token) {
    server.handleClientConnection(
      params.capabilities,
      params.initializationOptions,
    );

    final openWorkspacePaths = <String>[];
    // The onlyAnalyzeProjectsWithOpenFiles flag allows opening huge folders
    // without setting them as analysis roots. Instead, analysis roots will be
    // based only on the open files.
    // if (!server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles) {
    // if (params.workspaceFolders != null) {
    //   params.workspaceFolders.forEach((wf) {
    //     final uri = Uri.parse(wf.uri);
    //     // Only file URIs are supported, but there's no way to signal this to
    //     // the LSP client (and certainly not before initialization).
    //     if (uri.isScheme('file')) {
    //       openWorkspacePaths.add(uri.toFilePath());
    //     }
    //   });
    // }
    if (params.rootUri != null) {
      final uri = Uri.parse(params.rootUri);
      if (uri.isScheme('file')) {
        openWorkspacePaths.add(uri.toFilePath());
      }
    } else if (params.rootPath != null) {
      openWorkspacePaths.add(params.rootPath);
    }
    // }

    server.messageHandler = InitializingStateMessageHandler(
      server,
      openWorkspacePaths,
    );

    server.logger.folder = openWorkspacePaths.first;
    server.logger.log('initialized!');
    server.logger.log('Open workspace paths: $openWorkspacePaths');
    // server.logger.log('Client capibilities: ${params.capabilities}');
    server.logger
        .log('Client initialization option: ${params.initializationOptions}');

    server.capabilities = server.capabilitiesComputer
        .computeServerCapabilities(server.clientCapabilities);

    // var sdkVersion = Platform.version;
    // if (sdkVersion.contains(' ')) {
    //   sdkVersion = sdkVersion.substring(0, sdkVersion.indexOf(' '));
    // }

    return success(InitializeResult(
      // capabilities: null,
      capabilities: server.capabilities,
      serverInfo: InitializeResultServerInfo(
        name: hetuLanguageServerName,
        version: hetuLanguageServerVersion,
      ),
    ));
  }
}
