import '../grammar/lexicon.dart';

import 'unresolved_type.dart';

/// A Generic Type Parameter could be:
/// ```
///   Type<T>
///   Type<T extends Person>
/// ```
class HTGenericTypeParameter {
  final String id;

  final HTUnresolvedType? superType;

  HTGenericTypeParameter(this.id, {this.superType});

  @override
  String toString() {
    if (superType == null) {
      return id;
    } else {
      return '$id ${HTLexicon.EXTENDS} $superType';
    }
  }
}
