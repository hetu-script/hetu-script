import 'errors.dart';

/// A [HTDeclaration] could be a [HTVariable], a [HTClass] or a [HTFunction]
abstract class HTDeclaration {
  late final String id;
  String? classId;

  /// A [HTDeclaration] is uncloneable by default.
  HTDeclaration clone() => throw HTError.clone(id);
}
