// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'error.dart';

/// String identifiers mapped to associated severities.
const Map<String, ErrorSeverity> severityMap = {
  'error': ErrorSeverity.error,
  'info': ErrorSeverity.info,
  'warning': ErrorSeverity.warning
};

/// Error processor configuration derived from analysis (or embedder) options.
class ErrorConfig {
  static const List<String> ignoreWords = ['ignore', 'false'];

  static ErrorSeverity? _toSeverity(String? severity) => severityMap[severity];

  /// The processors in this config.
  final List<ErrorProcessor> processors = <ErrorProcessor>[];

  /// Create an error config for the given error code map.
  /// For example:
  ///     new ErrorConfig({'missing_return' : 'error'});
  /// will create a processor config that turns `missing_return` hints into
  /// errors.
  ErrorConfig([Map<String, String>? codeMap]) {
    if (codeMap != null) {
      for (final code in codeMap.keys) {
        final value = codeMap[code]!;

        var action = value.toLowerCase();
        if (ignoreWords.contains(action)) {
          processors.add(ErrorProcessor(code));
        } else {
          final severity = _toSeverity(action);
          if (severity != null) {
            processors.add(ErrorProcessor(code, severity));
          }
        }
      }
    }
  }
}

/// Process errors by filtering or changing associated [ErrorSeverity].
class ErrorProcessor {
  /// The code name of the associated error.
  final String name;

  /// The desired severity of the processed error.
  ///
  /// If `null`, this processor will "filter" the associated error code.
  final ErrorSeverity? severity;

  /// Create an error processor that assigns errors with this [code] the
  /// given [severity].
  ///
  /// If [severity] is `null`, matching errors will be filtered.
  const ErrorProcessor(this.name, [this.severity]);

  /// The string that unique describes the processor.
  String get description => '$name -> ${severity?.name}';

  /// Check if this processor applies to the given [error].
  bool appliesTo(HTError error) => name == error.name;

  /// Return an error processor associated in the [analysisOptions] for the
  /// given [error], or `null` if none is found.
  static ErrorProcessor? getProcessor(HTAnalyzer? analyzer, HTError error) {
    if (analyzer == null) {
      return null;
    }

    for (var processor in analyzer.errorProcessors) {
      if (processor.appliesTo(error)) {
        return processor;
      }
    }
    return null;
  }
}
