import '../source/source.dart';
import 'context.dart';

/// Manage a set of contexts.
abstract class HTContextManager {
  Iterable<HTContext> get contexts;

  bool hasSource(String fullName);

  void addSource(String fullName, String content,
      {SourceType type = SourceType.module, bool isLibraryEntry = false});

  HTSource getSource(String fullName, {bool reload = false});

  /// Create context from a set of folders.
  ///
  /// The folder paths does not neccessarily be normalized.
  void setRoots(Iterable<String> folderPaths);

  /// Computes roots from a set of files.
  ///
  /// The file paths does not neccessarily be normalized.
  void setRootsFromFiles(Iterable<String> filePaths);

  /// Set up a callback for root updated event.
  void onRootsUpdated(Function callback);
}
