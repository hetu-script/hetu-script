import 'package:meta/meta.dart';

import 'namespace.dart';
import '../../error/error.dart';
import '../source/source.dart';
import '../source/source_range.dart';
import '../type/type.dart';
import 'object.dart';

/// Element is a semantic entity in the program that
/// represents things that are declared with a name
/// and hence can be referenced elsewhere in the code.
class HTElement with HTObject {
  final String id;

  final String? classId;

  @override
  HTType get valueType => HTType.DECLARATION;

  final String moduleFullName;

  final String libraryName;

  final HTSource? source;

  final SourceRange idRange;

  bool get isMember => classId != null;

  final bool isExternal;

  final bool isStatic;

  final bool isMutable;

  final bool isConst;

  /// Elements defined within this class, namespace, block etc.
  /// Element could be registerd with a key different from its id.
  final Map<String, HTElement> declarations;

  const HTElement(this.id, this.moduleFullName, this.libraryName,
      {this.source,
      this.idRange = SourceRange.EMPTY,
      this.classId,
      this.isExternal = false,
      this.isStatic = false,
      this.isMutable = false,
      this.isConst = false,
      this.declarations = const {}});

  dynamic get value => this;

  set value(dynamic newVal) {
    if (!isMutable || isConst) {
      throw HTError.immutable(id);
    }
  }

  @mustCallSuper
  void resolve(HTNamespace namespace) {}

  HTElement clone() => HTElement(id, moduleFullName, libraryName,
      classId: classId,
      isExternal: isExternal,
      isStatic: isStatic,
      isMutable: isMutable,
      isConst: isConst);
}
