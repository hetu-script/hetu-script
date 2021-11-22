import 'package:hetu_script/hetu_script.dart';

import 'file_system_context.dart';

class HTFileSystemContextManager
    extends HTResourceManager<HTFileSystemSourceContext> {
  @override
  final isSearchEnabled = true;

  @override
  HTFileSystemSourceContext createContext(String root) {
    return HTFileSystemSourceContext(root: root, cache: cachedSources);
  }
}
