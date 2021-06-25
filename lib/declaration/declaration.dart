import 'package:meta/meta.dart';

import '../type/type.dart';
import '../error/error.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../source/source_range.dart';
// import '../type/type.dart';
import '../object/object.dart';
import 'namespace.dart';

/// Element is a semantic entity in the program that
/// represents things that are declared with a name
/// and hence can be referenced elsewhere in the code.
abstract class HTDeclaration with HTObject {
  final String? id;

  String get name => id ?? ('${SemanticNames.anonymous} $valueType');

  bool get isPrivate => name.startsWith(HTLexicon.privatePrefix);

  final String? classId;

  final HTNamespace? closure;

  final HTSource? source;

  final SourceRange idRange;

  final SourceRange sourceRange;

  HTType? _declType;

  /// The declared [HTType] of this symbol, will be used to
  /// compare with the value type before compile to
  /// determine wether an value binding (assignment) is legal.
  HTType? get declType => _declType;

  bool get isMember => classId != null;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isMutable;

  HTDeclaration(
      {this.id,
      this.classId,
      this.closure,
      this.source,
      this.idRange = SourceRange.EMPTY,
      this.sourceRange = SourceRange.EMPTY,
      HTType? declType,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isMutable = false}) {
    _declType = declType;
  }

  dynamic get value => this;

  set value(dynamic newVal) {
    if (!isMutable || isConst) {
      throw HTError.immutable(name);
    }
  }

  @mustCallSuper
  void resolve() {
    if ((closure != null) && (_declType != null) && (!_declType!.isResolved)) {
      _declType = _declType!.resolve(closure!);
    }
  }

  HTDeclaration clone();
}
