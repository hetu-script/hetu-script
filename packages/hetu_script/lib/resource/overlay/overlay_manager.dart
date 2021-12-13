import '../resource_manager.dart';
import '../../source/source.dart';
import 'overlay_context.dart';

class HTOverlayContextManager
    extends HTSourceManager<HTSource, HTOverlayContext> {
  @override
  bool get isSearchEnabled => false;

  @override
  HTOverlayContext createContext(String root) {
    return HTOverlayContext(root: root, cache: cachedSources);
  }
}
