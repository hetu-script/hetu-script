import 'errors.dart';

/// A [HTDeclaration] could be a [HTVariable], a [HTClass] or a [HTFunction]
abstract class HTDeclaration {
  late final String id;

  HTDeclaration clone() => throw HTErrorClone(id);
}
