import 'package:hetu_script/declaration/namespace/module.dart';

import '../../grammar/semantic.dart';
import 'namespace.dart';

/// [HTLibrary] is the semantic entity of a program or package
/// it contains all object and code interpreter generated.
class HTLibrary extends HTNamespace {
  @override
  String toString() => '${SemanticNames.library} $id';

  @override
  final String id;

  @override
  final Map<String, HTModule> declarations;

  HTLibrary(this.id, {Map<String, HTModule>? declarations})
      : declarations = declarations ?? <String, HTModule>{},
        super(id: id);
}
