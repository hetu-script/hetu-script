import '../../type/type.dart';

/// A Generic Type Parameter could be:
/// ```
///   Type<T>
///   Type<T extends Person>
/// ```
class HTGenericTypeParameter {
  final String id;

  final HTType? superType;

  HTGenericTypeParameter(this.id, {this.superType});
}
