import 'dart:async';

// import 'package:path/path.dart' as path;

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

import 'channel/lsp_channel.dart';
import '../protocol/protocol_common.dart';
import '../protocol/protocol_generated.dart';
import '../protocol/protocol_special.dart';
import '../protocol/protocol_internal.dart';
// import 'protocol/protocol_server.dart';
import 'handler/handlers.dart';
import 'client_configuration.dart';
import 'capability/client_capabilities.dart';
import 'capability/server_capabilities_computer.dart';
import 'handler/handler_states.dart';
import 'mapping.dart';

import 'constants.dart';

// import 'abstract_lsp_server.dart';

// ignore_for_file: import_of_legacy_library_into_null_safe

/// Instances of the class [LspAnalysisServer] implement an LSP-based server
/// that listens on a [CommunicationChannel] for LSP messages and processes
/// them.
class LspAnalysisServer {
  /// Configuration for the workspace from the client. This is similar to
  /// initializationOptions but can be updated dynamically rather than set
  /// only when the server starts.
  final LspClientConfiguration clientConfiguration = LspClientConfiguration();

  /// Initialization options provided by the LSP client. Allows opting in/out of
  /// specific server functionality. Will be null prior to initialization.
  late final LspInitializationOptions _initializationOptions;
  LspInitializationOptions get initializationOptions => _initializationOptions;

  /// The capabilities of the LSP client. Will be null prior to initialization.
  late final LspClientCapabilities _clientCapabilities;
  LspClientCapabilities get clientCapabilities => _clientCapabilities;

  /// Capabilities of the server. Will be null prior to initialization as
  /// the server capabilities depend on the client capabilities.
  ServerCapabilities? capabilities;
  late final ServerCapabilitiesComputer capabilitiesComputer;

  ServerStateMessageHandler? messageHandler;

  /// The channel from which messages are received and to which responses should
  /// be sent.
  final LspServerCommunicationChannel channel;

  /// The versions of each document known to the server (keyed by path), used to
  /// send back to the client for server-initiated edits so that the client can
  /// ensure they have a matching version of the document before applying them.
  ///
  /// Handlers should prefer to use the `getVersionedDocumentIdentifier` method
  /// which will return a null-versioned identifier if the document version is
  /// not known.
  final Map<String, VersionedTextDocumentIdentifier> documentVersions = {};

  int nextRequestId = 1;

  final Map<int, Completer<ResponseMessage>> completers = {};

  /// Whether or not the server is controlling the shutdown and will exit
  /// automatically.
  bool willExit = false;

  /// The set of the files that are currently priority.
  final Set<String> _openFiles = <String>{};

  /// The current workspace folders provided by the client.
  final _workspaceFolders = <String>{};

  late final HTAnalysisManager analysisManager;

  HTContextManager get contextManager => analysisManager.contextManager;

  final HTLogger logger = HTFileSystemLogger();

  /// Initialize a newly created server to send and receive messages to the
  /// given [channel].
  LspAnalysisServer(
    this.channel,
  ) {
    messageHandler = UninitializedStateMessageHandler(this);
    capabilitiesComputer = ServerCapabilitiesComputer(this);
    analysisManager = HTAnalysisManager(HTOverlayContextManager());

    channel.listen(handleMessage, onDone: done, onError: socketError);
  }

  Future<void> get exited => channel.closed;

  /// The socket from which messages are being read has been closed.
  void done() {}

  Future<void> shutdown() {
    // Defer closing the channel so that the shutdown response can be sent and
    // logged.
    Future(() {
      channel.close();
    });

    return Future.value();
  }

  /// There was an error related to the socket from which messages are being
  /// read.
  void socketError(error, stack) {
    // Don't send to instrumentation service; not an internal error.
    // sendServerErrorNotification('Socket error', error, stack);
  }

  void updateWorkspaceFolders(
      List<String> addedPaths, List<String> removedPaths) {
    _workspaceFolders
      ..addAll(addedPaths)
      ..removeAll(removedPaths);

    _refreshAnalysisRoots();
  }

  void _refreshAnalysisRoots() {
    // When there are open folders, they are always the roots. If there are no
    // open workspace folders, then we use the open (priority) files to compute
    // roots.
    final includedPaths =
        _workspaceFolders.isNotEmpty ? _workspaceFolders : _openFiles;

    // final excludedPaths = clientConfiguration.analysisExcludedFolders
    //     .expand((excludePath) => path.isAbsolute(excludePath)
    //         ? [excludePath]
    //         // Apply the relative path to each open workspace folder.
    //         // TODO(dantup): Consider supporting per-workspace config by
    //         // calling workspace/configuration whenever workspace folders change
    //         // and caching the config for each one.
    //         : _workspaceFolders.map((root) => path.join(root, excludePath)))
    //     .toSet();

    contextManager.setRoots(includedPaths); //, excludedPaths.toList());
  }

  /// Fetches configuration from the client (if supported) and then sends
  /// register/unregister requests for any supported/enabled dynamic registrations.
  Future<void> fetchClientConfigurationAndPerformDynamicRegistration() async {
    if (clientCapabilities.configuration) {
      // Fetch all configuration we care about from the client. This is just
      // "hetu" for now, but in future this may be extended to include
      // others (for example "dart", "flutter").
      final response = await sendRequest(
          Method.workspace_configuration,
          ConfigurationParams(items: [
            ConfigurationItem(section: 'hetu'),
          ]));

      final result = response.result;

      // Expect the result to be a single list (to match the single
      // ConfigurationItem we requested above) and that it should be
      // a standard map of settings.
      // If the above code is extended to support multiple sets of config
      // this will need tweaking to handle each group appropriately.
      if (result != null &&
          result is List<dynamic> &&
          result.length == 1 &&
          result.first is Map<String, dynamic>) {
        final newConfig = result.first;
        // final refreshRoots =
        //     clientConfiguration.affectsAnalysisRoots(newConfig);

        clientConfiguration.replace(newConfig);

        // if (refreshRoots) {
        //   _refreshAnalysisRoots();
        // }
      }
    }

    // Client config can affect capabilities, so this should only be done after
    // we have the initial/updated config.
    await capabilitiesComputer.performDynamicRegistration();
  }

  LineInfo getLineInfo(String path) {
    return contextManager.getSource(path)!.lineInfo;
  }

  /// Gets the version of a document known to the server, returning a
  /// [OptionalVersionedTextDocumentIdentifier] with a version of `null` if the document
  /// version is not known.
  OptionalVersionedTextDocumentIdentifier getVersionedDocumentIdentifier(
      String path) {
    return OptionalVersionedTextDocumentIdentifier(
        uri: Uri.file(path).toString(),
        version: documentVersions[path]?.version);
  }

  void handleClientConnection(
      ClientCapabilities capabilities, dynamic initializationOptions) {
    _clientCapabilities = LspClientCapabilities(capabilities);
    _initializationOptions = LspInitializationOptions(initializationOptions);
  }

  /// Handles a response from the client by invoking the completer that the
  /// outbound request created.
  void handleClientResponse(ResponseMessage message) {
    // The ID from the client is an Either2<num, String>, though it's not valid
    // for it to be a string because it should match a request we sent to the
    // client (and we always use numeric IDs for outgoing requests).
    message.id.map(
      (id) {
        // It's possible that even if we got a numeric ID that it's not valid.
        // If it's not in our completers list (which is a list of the
        // outstanding requests we've sent) then show an error.
        final completer = completers[id];
        if (completer == null) {
          showErrorMessageToUser('Response with ID $id was unexpected');
        } else {
          completers.remove(id);
          completer.complete(message);
        }
      },
      (stringID) {
        showErrorMessageToUser('Unexpected String ID for response $stringID');
      },
    );
  }

  /// Handle a [message] that was read from the communication channel.
  void handleMessage(Message message) {
    logger.log('received client message: $message');

    runZonedGuarded(() async {
      try {
        if (message is ResponseMessage) {
          handleClientResponse(message);
        } else if (message is RequestMessage) {
          final result = await messageHandler!.handleMessage(message);
          if (result.isError) {
            sendErrorResponse(message, result.error);
          } else {
            channel.sendResponse(ResponseMessage(
                id: message.id,
                result: result.result,
                jsonrpc: jsonRpcVersion));
          }
        } else if (message is NotificationMessage) {
          final result = await messageHandler!.handleMessage(message);
          if (result.isError) {
            sendErrorResponse(message, result.error);
          }
        } else {
          showErrorMessageToUser('Unknown message type');
        }
      } catch (error, stackTrace) {
        logger.log('error when handling client message:\n$error');

        final errorMessage = message is ResponseMessage
            ? 'An error occurred while handling the response to request ${message.id}\n$error'
            : message is RequestMessage
                ? 'An error occurred while handling ${message.method} request\n$error'
                : message is NotificationMessage
                    ? 'An error occurred while handling ${message.method} notification\n$error'
                    : 'Unknown message type';
        sendErrorResponse(
            message,
            ResponseError(
              code: ServerErrorCodes.UnhandledError,
              message: errorMessage,
            ));
        logException(errorMessage, error, stackTrace);
      }
    }, socketError);
  }

  /// Logs the error on the client using window/logMessage.
  void logErrorToClient(String message) {
    logger.log('sending notification: $message');

    channel.sendNotification(NotificationMessage(
      method: Method.window_logMessage,
      params: LogMessageParams(type: MessageType.Error, message: message),
      jsonrpc: jsonRpcVersion,
    ));
  }

  /// Logs an exception by sending it to the client (window/logMessage) and
  /// recording it in a buffer on the server for diagnostics.
  void logException(String message, exception, stackTrace) {
    var fullMessage = message;
    // if (exception is CaughtException) {
    //   stackTrace ??= exception.stackTrace;
    //   fullMessage = '$fullMessage: ${exception.exception}';
    // } else if (exception != null) {
    //   fullMessage = '$fullMessage: $exception';
    // }

    final fullError =
        stackTrace == null ? fullMessage : '$fullMessage\n$stackTrace';

    // Log the full message since showMessage above may be truncated or
    // formatted badly (eg. VS Code takes the newlines out).
    logErrorToClient(fullError);

    logger.log('exception: $fullError');

    // remember the last few exceptions
    // exceptions.add(ServerException(
    //   message,
    //   exception,
    //   stackTrace is StackTrace ? stackTrace : null,
    //   false,
    // ));

    // instrumentationService.logException(
    //   FatalException(
    //     message,
    //     exception,
    //     stackTrace,
    //   ),
    //   null,
    //   crashReportingAttachmentsBuilder.forException(exception),
    // );
  }

  void doAnalyze(String path) {
    // // If the file did not exist, and is "overlay only", it still should be
    // // analyzed. Add it to driver to which it should have been added.
    final result = analysisManager.analyze(path);

    var errors = <AnalysisError>[];
    if (result.errors.isNotEmpty) {
      errors = doAnalysisError_listFromEngine(result);
    }
    sendAnalysisErrors(path, errors);
  }

  void onOverlayCreated(String path, String content) {
    final source = contextManager.addSource(path, content);

    logger.log('source added: [${source.fullName}]\n${source.content}');

    logger.log('pathsToAnalyze:\n${analysisManager.pathsToAnalyze}');

    doAnalyze(source.fullName);

    // _afterOverlayChanged(path, plugin.AddContentOverlay(content));
  }

  void onOverlayDestroyed(String path) {
    // resourceProvider.removeOverlay(path);

    // _afterOverlayChanged(path); //, RemoveContentOverlay());
  }

  /// Updates an overlay on [path] by applying the [edits] to the current
  /// overlay.
  ///
  /// If the result of applying the edits is already known, [newContent] can be
  /// set to avoid doing that calculation twice.
  void onOverlayUpdated(String path, List<SourceEdit> edits,
      {String? newContent}) {
    // assert(resourceProvider.hasOverlay(path));
    final source = contextManager.getSource(path)!;
    if (newContent == null) {
      final oldContent = source.content;
      newContent = applySequenceOfEdits(oldContent, edits);
    }

    // this is a more direct way than calling updateSource on contextManager
    source.content = newContent;

    logger.log(
        'updated source: ${source.fullName}, edits:\n${edits.map((edit) => edit.toString())}');

    doAnalyze(source.fullName);

    // resourceProvider.setOverlay(path,
    //     content: newContent, modificationStamp: overlayModificationStamp++);

    // _afterOverlayChanged(path); //, ChangeContentOverlay(edits));
  }

  // void _afterOverlayChanged(String path) {
  //   , dynamic changeForPlugins) {

  //   driverMap.values.forEach((driver) => driver.changeFile(path));
  //   pluginManager.setAnalysisUpdateContentParams(
  //     plugin.AnalysisUpdateContentParams({path: changeForPlugins}),
  //   );

  //   notifyDeclarationsTracker(path);
  //   notifyFlutterWidgetDescriptions(path);
  // }

  // void publishClosingLabels(String path, List<ClosingLabel> labels) {
  //   final params = PublishClosingLabelsParams(
  //       uri: Uri.file(path).toString(), labels: labels);
  //   final message = NotificationMessage(
  //     method: CustomMethods.publishClosingLabels,
  //     params: params,
  //     jsonrpc: jsonRpcVersion,
  //   );
  //   sendNotification(message);
  // }

  void publishDiagnostics(String path, List<Diagnostic> errors) {
    final params = PublishDiagnosticsParams(
        uri: Uri.file(path).toString(), diagnostics: errors);
    final message = NotificationMessage(
      method: Method.textDocument_publishDiagnostics,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendNotification(message);
  }

  // void publishOutline(String path, Outline outline) {
  //   final params =
  //       PublishOutlineParams(uri: Uri.file(path).toString(), outline: outline);
  //   final message = NotificationMessage(
  //     method: CustomMethods.publishOutline,
  //     params: params,
  //     jsonrpc: jsonRpcVersion,
  //   );
  //   sendNotification(message);
  // }

  void addOpenFile(String path) {
    _openFiles.add(path);
  }

  void removeOpenFile(String path) {
    _openFiles.remove(path);
  }

  void sendErrorResponse(Message message, ResponseError error) {
    if (message is RequestMessage) {
      channel.sendResponse(ResponseMessage(
          id: message.id, error: error, jsonrpc: jsonRpcVersion));
    } else if (message is ResponseMessage) {
      // For bad response messages where we can't respond with an error, send it
      // as show instead of log.
      showErrorMessageToUser(error.message);
    } else {
      // For notifications where we couldn't respond with an error, send it as
      // show instead of log.
      showErrorMessageToUser(error.message);
    }

    // Handle fatal errors where the client/server state is out of sync and we
    // should not continue.
    if (error.code == ServerErrorCodes.ClientServerInconsistentState) {
      // Do not process any further messages.
      messageHandler = FailureStateMessageHandler(this);

      final message = 'An unrecoverable error occurred.';
      logErrorToClient(
          '$message\n\n${error.message}\n\n${error.code}\n\n${error.data}');

      shutdown();
    }
  }

  /// Send the given [notification] to the client.
  void sendNotification(NotificationMessage notification) {
    channel.sendNotification(notification);
  }

  /// Send the given [request] to the client and wait for a response. Completes
  /// with the raw [ResponseMessage] which could be an error response.
  Future<ResponseMessage> sendRequest(Method method, Object params) {
    logger.log('send request: $method, $params');

    final requestId = nextRequestId++;
    final completer = Completer<ResponseMessage>();
    completers[requestId] = completer;

    channel.sendRequest(RequestMessage(
      id: Either2<num, String>.t1(requestId),
      method: method,
      params: params,
      jsonrpc: jsonRpcVersion,
    ));

    return completer.future;
  }

  /// Send the given [response] to the client.
  void sendResponse(ResponseMessage response) {
    logger.log('send response: $response');

    channel.sendResponse(response);
  }

  void sendAnalysisErrors(String filePath, List<AnalysisError> errors) {
    final diagnostics = errors
        .map((error) => analysisErrorToDiagnostic(getLineInfo, error))
        .toList();

    final params = PublishDiagnosticsParams(
        uri: Uri.file(filePath).toString(), diagnostics: diagnostics);
    final message = NotificationMessage(
      method: Method.textDocument_publishDiagnostics,
      params: params,
      jsonrpc: jsonRpcVersion,
    );

    channel.sendNotification(message);
  }

  void showErrorMessageToUser(String message) {
    showMessageToUser(MessageType.Error, message);
  }

  void showMessageToUser(MessageType type, String message) {
    channel.sendNotification(NotificationMessage(
      method: Method.window_showMessage,
      params: ShowMessageParams(type: type, message: message),
      jsonrpc: jsonRpcVersion,
    ));
  }
}

class LspInitializationOptions {
  final bool onlyAnalyzeProjectsWithOpenFiles;
  final bool suggestFromUnimportedLibraries;
  final bool closingLabels;
  final bool outline;
  final bool flutterOutline;

  LspInitializationOptions(dynamic options)
      : onlyAnalyzeProjectsWithOpenFiles = options != null &&
            options['onlyAnalyzeProjectsWithOpenFiles'] == true,
        // suggestFromUnimportedLibraries defaults to true, so must be
        // explicitly passed as false to disable.
        suggestFromUnimportedLibraries = options == null ||
            options['suggestFromUnimportedLibraries'] != false,
        closingLabels = options != null && options['closingLabels'] == true,
        outline = options != null && options['outline'] == true,
        flutterOutline = options != null && options['flutterOutline'] == true;
}
