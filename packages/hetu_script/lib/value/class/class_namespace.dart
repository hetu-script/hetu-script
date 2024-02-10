import '../../error/error.dart';
// import '../../source/source.dart';
import '../function/function.dart';
import '../namespace/namespace.dart';
import 'class.dart';
import '../../common/internal_identifier.dart';

/// A implementation of [HTNamespace] for [HTClass].
/// For interpreter searching for symbols within static methods.
class HTClassNamespace extends HTNamespace {
  final HTClass klass;

  HTClassNamespace({
    required this.klass,
    required super.lexicon,
    super.id,
    super.classId,
    super.closure,
    super.source,
  });

  @override
  dynamic memberGet(
    String id, {
    bool isPrivate = false,
    String? from,
    bool isRecursive = true,
    bool throws = true,
    bool asDeclaration = false,
  }) {
    final getter = '${InternalIdentifier.getter}$id';
    final externalStatic = '$id.$id';

    if (symbols.containsKey(id)) {
      final decl = symbols[id]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(id);
      }
      decl.resolve();
      return decl.value;
    } else if (symbols.containsKey(getter)) {
      final decl = symbols[getter]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(id);
      }
      decl.resolve();
      return decl.value;
    } else if (symbols.containsKey(externalStatic)) {
      final decl = symbols[externalStatic]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(id);
      }
      decl.resolve();
      return decl.value;
    }

    if (isRecursive && (closure != null)) {
      return closure!
          .memberGet(id, from: from, isRecursive: isRecursive, throws: throws);
    }

    if (throws) {
      throw HTError.undefined(id);
    }
  }

  @override
  bool memberSet(
    String id,
    dynamic value, {
    String? from,
    bool isRecursive = true,
    bool throws = true,
  }) {
    final setter = '${InternalIdentifier.setter}$id';
    if (symbols.containsKey(id)) {
      final decl = symbols[id]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(id);
      }
      decl.resolve();
      decl.value = value;
      return true;
    } else if (symbols.containsKey(setter)) {
      final decl = symbols[setter]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(id);
      }
      decl.resolve();
      final setterFunc = decl as HTFunction;
      setterFunc.call(positionalArgs: [value]);
      return true;
    }

    if (isRecursive && closure != null) {
      return closure!.memberSet(id, value,
          from: from, isRecursive: isRecursive, throws: throws);
    }

    if (throws) {
      throw HTError.undefined(id);
    } else {
      return false;
    }
  }
}
