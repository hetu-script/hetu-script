import 'package:hetu_script/value/function/function.dart';

import '../../error/error.dart';
import '../../grammar/constant.dart';
import '../../value/namespace/namespace.dart';
import 'instance.dart';

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
      {required String id,
      required this.instance,
      HTInstanceNamespace? runtimeInstanceNamespace,
      String? classId,
      HTNamespace? closure})
      : super(id: id, classId: classId, closure: closure) {
    this.runtimeInstanceNamespace = runtimeInstanceNamespace ?? this;
  }

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [memberGet],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try fetching variable from enclosed namespace.
  @override
  dynamic memberGet(String varName,
      {bool isPrivate = false,
      String? from,
      bool recursive = true,
      bool error = true}) {
    final getter = '${InternalIdentifier.getter}$varName';

    HTInstanceNamespace? curNamespace = runtimeInstanceNamespace;
    while (curNamespace != null) {
      if (curNamespace.symbols.containsKey(varName) ||
          curNamespace.symbols.containsKey(getter)) {
        final value =
            instance.memberGet(varName, from: from, cast: curNamespace.classId);
        if (value is HTFunction) {
          value.instance = instance;
        }
        return value;
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      return closure!.memberGet(varName, from: from, recursive: recursive);
    }

    if (error) {
      throw HTError.undefined(varName);
    }
  }

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [memberSet],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try assigning variable from enclosed namespace.
  @override
  bool memberSet(String varName, dynamic varValue,
      {String? from, bool recursive = true, bool error = true}) {
    final setter = '${InternalIdentifier.getter}$varName';

    HTInstanceNamespace? curNamespace = runtimeInstanceNamespace;
    while (curNamespace != null) {
      if (curNamespace.symbols.containsKey(varName) ||
          curNamespace.symbols.containsKey(setter)) {
        instance.memberSet(varName, varValue,
            from: from, cast: curNamespace.classId);
        return true;
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      return closure!.memberSet(varName, varValue, from: from);
    }

    if (error) {
      throw HTError.undefined(varName);
    } else {
      return false;
    }
  }
}
