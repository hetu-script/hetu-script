import 'package:hetu_script/ast/ast_compilation.dart';
import 'package:hetu_script/hetu_script.dart';

import 'namespace.dart';

class HTLibrary extends HTNamespace {
  @override
  final String id;

  @override
  final Map<String, HTNamespace> declarations = {};

  final Map<String, HTSource> sources = {};

  HTLibrary(this.id) : super(id: id);
}
