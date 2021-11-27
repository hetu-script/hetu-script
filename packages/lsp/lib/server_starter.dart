import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';

import 'lsp/lsp_analysis_server.dart';

import 'lsp/channel/lsp_byte_stream_channel.dart';

// ignore_for_file: import_of_legacy_library_into_null_safe

typedef PrintFunction = void Function(String line);

class HTLanguageServer {
  static const _singleton = HTLanguageServer._();

  const HTLanguageServer._();

  factory HTLanguageServer() {
    return _singleton;
  }

  dynamic start(List<String> args) {
    var parser = createArgParser();
    var results = parser.parse(args);

    startStdioLspServer(results);
  }

  void startStdioLspServer(ArgResults args) {
    var stdioChannel = LspByteStreamServerChannel(stdin, stdout.nonBlocking);
    _captureExceptions(() {
      final server = LspAnalysisServer(stdioChannel);
      stdioChannel.closed.then((_) async {
        // Only shutdown the server and exit if the server is not already
        // handling the shutdown.
        if (!server.willExit) {
          await server.shutdown();
          exit(0);
        }
      });
    });
  }

  /// Execute the given [callback] within a zone that will capture any unhandled
  /// exceptions and both report them to the client and send them to the given
  /// instrumentation [service]. If a [print] function is provided, then also
  /// capture any data printed by the callback and redirect it to the function.
  void _captureExceptions(
      // InstrumentationService service,
      void Function() callback,
      {PrintFunction? print}) {
    void errorFunction(Zone self, ZoneDelegate parent, Zone zone,
        dynamic exception, StackTrace stackTrace) {
      // service.logException(exception, stackTrace);
      throw exception;
    }

    var printFunction = print == null
        ? null
        : (Zone self, ZoneDelegate parent, Zone zone, String line) {
            // Note: we don't pass the line on to stdout, because that is
            // reserved for communication to the client.
            print(line);
          };
    var zoneSpecification = ZoneSpecification(
        handleUncaughtError: errorFunction, print: printFunction);
    return runZoned(callback, zoneSpecification: zoneSpecification);
  }

  /// Create and return the parser used to parse the command-line arguments.
  static ArgParser createArgParser() {
    var parser = ArgParser();
    parser.addOption('client-id',
        valueHelp: 'name',
        help: 'An identifier for the analysis server client.');
    parser.addOption('client-version',
        valueHelp: 'version',
        help: 'The version of the analysis server client.');
    parser.addOption('hetu-sdk-version',
        valueHelp: 'path', help: 'Override the Dart SDK to use for analysis.');

    parser.addFlag('internal-print-to-console',
        help: 'enable sending `print` output to the console',
        defaultsTo: false,
        negatable: false,
        hide: true);

    return parser;
  }
}
