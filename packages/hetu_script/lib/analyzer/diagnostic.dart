// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../error/error_severity.dart';

/// A diagnostic, as defined by the [Diagnostic Design Guidelines][guidelines]:
///
/// > An indication of a specific problem at a specific location within the
/// > source code being processed by a development tool.
///
/// Clients may not extend, implement or mix-in this class.
///
/// [guidelines]: ../doc/diagnostics.md
class HTDiagnostic {
  /// A list of messages that provide context for understanding the problem
  /// being reported. The list will be empty if there are no such messages.
  final List<HTDiagnosticMessage> contextMessages;

  /// A description of how to fix the problem, or `null` if there is no such
  /// description.
  final String? correctionMessage;

  /// A message describing what is wrong and why.
  final HTDiagnosticMessage problemMessage;

  /// The severity associated with the diagnostic.
  final ErrorSeverity severity;

  HTDiagnostic(this.contextMessages, this.correctionMessage,
      this.problemMessage, this.severity);
}

/// A single message associated with a [HTDiagnostic], consisting of the text of
/// the message and the location associated with it.
///
/// Clients may not extend, implement or mix-in this class.
class HTDiagnosticMessage {
  /// The absolute and normalized path of the file associated with this message.
  final String filename;

  /// The zero-based offset from the start of the file to the beginning of the
  /// source range associated with this message.
  final int offset;

  /// The length of the source range associated with this message.
  final int length;

  /// The text of the message.
  final String message;

  HTDiagnosticMessage(this.filename, this.offset, this.length, this.message);
}
