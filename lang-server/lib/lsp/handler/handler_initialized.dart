// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import '../../protocol/protocol_generated.dart';
import '../../protocol/protocol_special.dart';
import '../lsp_analysis_server.dart';
import 'handler_states.dart';
import 'handlers.dart';

class IntializedMessageHandler extends MessageHandler<InitializedParams, void> {
  final List<String> openWorkspacePaths;
  IntializedMessageHandler(
    LspAnalysisServer server,
    this.openWorkspacePaths,
  ) : super(server);
  @override
  Method get handlesMessage => Method.initialized;

  @override
  LspJsonHandler<InitializedParams> get jsonHandler =>
      InitializedParams.jsonHandler;

  @override
  Future<ErrorOr<void>> handle(
      InitializedParams params, CancellationToken token) async {
    server.messageHandler = InitializedStateMessageHandler(
      server,
    );

    await server.fetchClientConfigurationAndPerformDynamicRegistration();

    // if (!server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles) {
    server.updateWorkspaceFolders(openWorkspacePaths, const []);
    // }

    return success();
  }
}
