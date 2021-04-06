import 'errors.dart';

/// A [HTDeclaration] could be a [HTVariable], a [HTClass] or a [HTFunction]
abstract class HTDeclaration {
  late final String id;
  late final String? classId;

  HTDeclaration clone() => throw HTError.clone(id);
}
