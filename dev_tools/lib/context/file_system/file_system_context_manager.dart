import 'package:hetu_script/hetu_script.dart';

import 'file_system_context.dart';

class HTFileSystemContextManager extends HTContextManager<HTFileSystemContext> {
  @override
  final isSearchEnabled = true;

  @override
  HTFileSystemContext createContext(String root) {
    return HTFileSystemContext(root: root, cache: cachedSources);
  }
}
