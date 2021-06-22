import '../../error/error.dart';
import '../../grammar/semantic.dart';
import '../namespace.dart';
import 'instance.dart';

/// A implementation of [HTNamespace] for [HTInstance].
/// For interpreter searching for symbols within instance methods.
/// [HTInstanceNamespace] is a singly linked list node,
/// it holds its super classes' [HTInstanceNamespace]'s referrences.
class HTInstanceNamespace extends HTNamespace {
  final HTInstance instance;

  late final HTInstanceNamespace? next;

  HTInstanceNamespace(
      String id, String moduleFullName, String libraryName, this.instance,
      {String? classId, HTNamespace? closure})
      : super(moduleFullName, libraryName,
            id: id, classId: classId, closure: closure);

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [memberGet],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try fetching variable from enclosed namespace.
  @override
  dynamic memberGet(String field,
      {String from = SemanticNames.global,
      bool error = true,
      bool recursive = true}) {
    final getter = '${SemanticNames.getter}$field';

    HTInstanceNamespace? curNamespace = this;
    while (curNamespace != null) {
      if (curNamespace.declarations.containsKey(field) ||
          curNamespace.declarations.containsKey(getter)) {
        return instance.memberGet(field,
            from: from, classId: curNamespace.classId);
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      return closure!.memberGet(field, from: from);
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
      {String from = SemanticNames.global,
      bool recursive = true,
      bool error = true}) {
    final setter = '${SemanticNames.getter}$field';

    HTInstanceNamespace? curNamespace = this;
    while (curNamespace != null) {
      if (curNamespace.declarations.containsKey(field) ||
          curNamespace.declarations.containsKey(setter)) {
        instance.memberSet(field, varValue,
            from: from, classId: curNamespace.classId);
        return;
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      closure!.memberSet(field, varValue, from: from);
      return;
    }

    throw HTError.undefined(field);
  }
}
