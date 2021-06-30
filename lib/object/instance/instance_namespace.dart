import '../../error/error.dart';
import '../../grammar/semantic.dart';
import '../../declaration/namespace.dart';
import 'instance.dart';

/// A implementation of [HTNamespace] for [HTInstance].
/// For interpreter searching for symbols within instance methods.
/// [HTInstanceNamespace] is a linked list node,
/// it holds its super classes' [HTInstanceNamespace]'s referrences.
class HTInstanceNamespace extends HTNamespace {
  final HTInstance instance;

  late final HTInstanceNamespace? next;

  HTInstanceNamespace(String id, this.instance,
      {String? classId, HTNamespace? closure})
      : super(id: id, classId: classId, closure: closure);

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [memberGet],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try fetching variable from enclosed namespace.
  @override
  dynamic memberGet(String field, {bool error = true, bool recursive = true}) {
    final getter = '${SemanticNames.getter}$field';

    HTInstanceNamespace? curNamespace = this;
    while (curNamespace != null) {
      if (curNamespace.declarations.containsKey(field) ||
          curNamespace.declarations.containsKey(getter)) {
        return instance.memberGet(field, cast: curNamespace.classId);
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      return closure!.memberGet(field);
    }

    if (error) {
      throw HTError.undefined(field);
    }
  }

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [memberSet],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try assigning variable from enclosed namespace.
  @override
  void memberSet(String field, dynamic varValue,
      {bool recursive = true, bool error = true}) {
    final setter = '${SemanticNames.getter}$field';

    HTInstanceNamespace? curNamespace = this;
    while (curNamespace != null) {
      if (curNamespace.declarations.containsKey(field) ||
          curNamespace.declarations.containsKey(setter)) {
        instance.memberSet(field, varValue, cast: curNamespace.classId);
        return;
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      closure!.memberSet(field, varValue);
      return;
    }

    throw HTError.undefined(field);
  }
}
