import '../context_manager.dart';
import 'overlay_context.dart';

class HTOverlayContextManager extends HTContextManager<HTOverlayContext> {
  @override
  final isSearchEnabled = false;

  @override
  HTOverlayContext createContext(String root) {
    return HTOverlayContext(root: root, cache: cachedSources);
  }
}
