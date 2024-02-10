import 'package:hetu_script/value/function/function.dart';

import '../../error/error.dart';
import '../../value/namespace/namespace.dart';
import 'instance.dart';
import '../../common/internal_identifier.dart';
import '../../common/function_category.dart';

/// A implementation of [HTNamespace] for [HTInstance].
/// For interpreter searching for symbols within instance methods.
/// [HTInstanceNamespace] is a linked list node,
/// it holds its super classes' [HTInstanceNamespace]'s referrences.
class HTInstanceNamespace extends HTNamespace {
  final HTInstance instance;

  /// The namespace of the runtime instance.
  late final HTInstanceNamespace runtimeInstanceNamespace;

  /// The namespace of the child class
  // late final HTInstanceNamespace? prev;

  /// The namespace of the super class
  late final HTInstanceNamespace? next;

  HTInstanceNamespace(
      {required super.lexicon,
      required String id,
      required this.instance,
      HTInstanceNamespace? runtimeInstanceNamespace,
      super.classId,
      super.closure})
      : super(id: id) {
    this.runtimeInstanceNamespace = runtimeInstanceNamespace ?? this;
  }

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [memberGet],
  /// with a new named parameter [isRecursive].
  /// If [isRecursive] is false, then it won't continue to
  /// try fetching variable from enclosed namespace.
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

    if (isRecursive) {
      HTInstanceNamespace? curNamespace = runtimeInstanceNamespace;
      while (curNamespace != null) {
        if (curNamespace.symbols.containsKey(id) ||
            curNamespace.symbols.containsKey(getter)) {
          final value =
              instance.memberGet(id, from: from, cast: curNamespace.classId);
          if (value is HTFunction &&
              value.category != FunctionCategory.literal) {
            value.instance = instance;
            value.namespace = this;
          }
          return value;
        } else {
          curNamespace = curNamespace.next;
        }
      }
    } else {
      if (symbols.containsKey(id)) {
        final value = instance.memberGet(id, from: from, cast: classId);
        if (value is HTFunction && value.category != FunctionCategory.literal) {
          value.instance = instance;
          value.namespace = this;
        }
        return value;
      }
    }

    if (isRecursive && closure != null) {
      return closure!.memberGet(id, from: from, isRecursive: isRecursive);
    }

    if (throws) {
      throw HTError.undefined(id);
    }
  }

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [memberSet],
  /// with a new named parameter [isRecursive].
  /// If [isRecursive] is false, then it won't continue to
  /// try assigning variable from enclosed namespace.
  @override
  bool memberSet(
    String id,
    dynamic value, {
    String? from,
    bool isRecursive = true,
    bool throws = true,
  }) {
    final setter = '${InternalIdentifier.getter}$id';

    if (isRecursive) {
      HTInstanceNamespace? curNamespace = runtimeInstanceNamespace;
      while (curNamespace != null) {
        if (curNamespace.symbols.containsKey(id) ||
            curNamespace.symbols.containsKey(setter)) {
          instance.memberSet(id, value, from: from, cast: curNamespace.classId);
          return true;
        } else {
          curNamespace = curNamespace.next;
        }
      }
    } else {
      if (symbols.containsKey(id) || symbols.containsKey(setter)) {
        instance.memberSet(id, value, from: from, cast: classId);
        return true;
      }
    }

    if (isRecursive && closure != null) {
      return closure!.memberSet(id, value, from: from);
    }

    if (throws) {
      throw HTError.undefined(id);
    } else {
      return false;
    }
  }
}
