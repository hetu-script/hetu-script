// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import '../../protocol/protocol_generated.dart';
import '../../protocol/protocol_special.dart';
import '../lsp_analysis_server.dart';
import 'handlers.dart';

/// A [MessageHandler] that rejects specific tpyes of messages with a given
/// error code/message.
class RejectMessageHandler extends MessageHandler<Object, void> {
  @override
  final Method handlesMessage;
  final ErrorCodes errorCode;
  final String errorMessage;
  RejectMessageHandler(LspAnalysisServer server, this.handlesMessage,
      this.errorCode, this.errorMessage)
      : super(server);

  @override
  LspJsonHandler<void> get jsonHandler => NullJsonHandler;

  @override
  ErrorOr<void> handle(void _, CancellationToken token) {
    return error(errorCode, errorMessage, null);
  }
}
