import 'package:quiver/core.dart';

import '../declaration/type/abstract_type_declaration.dart';
import 'type.dart';
import '../declaration/generic/generic_type_parameter.dart';

class HTParameterType {
  final HTType declType;

  /// Wether this is an optional parameter.
  final bool isOptional;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  bool get isNamed => id != null;

  /// Wether this is a named parameter.
  final String? id;

  const HTParameterType({
    this.id,
    required this.declType,
    required this.isOptional,
    required this.isVariadic,
  });
}

class HTFunctionType extends HTType implements HasGenericTypeParameter {
  @override
  final List<HTGenericTypeParameter> genericTypeParameters;

  final List<HTParameterType> _parameterTypes;

  List<HTParameterType>? _resolvedParameterTypes;

  List<HTParameterType> get parameterTypes =>
      _resolvedParameterTypes ?? _parameterTypes;

  final HTType? _returnType;

  HTType? _resolvedReturnType;

  HTType? get returnType => _resolvedReturnType ?? _returnType;

  HTFunctionType({
    this.genericTypeParameters = const [],
    List<HTParameterType> parameterTypes = const [],
    HTType? returnType,
  })  : _parameterTypes = parameterTypes,
        _returnType = returnType;

  @override
  bool operator ==(Object other) {
    return other is HTFunctionType && hashCode == other.hashCode;
  }

  @override
  int get hashCode {
    final hashList = [];
    hashList.add(id);
    // for (final typeArg in typeArgs) {
    //   hashList.add(typeArg.hashCode);
    // }
    hashList.add(genericTypeParameters.length.hashCode);
    for (final paramType in parameterTypes) {
      hashList.add(paramType);
    }
    hashList.add(returnType);
    final hash = hashObjects(hashList);
    return hash;
  }

  @override
  bool isA(HTType? other) {
    assert(other?.isResolved ?? true);

    if (other == null) return true;

    if (other.isTop) return true;

    if (other.isBottom) return false;

    if (other is HTTypeFunction) return true;

    if (other is! HTFunctionType) return false;

    if (genericTypeParameters.length != other.genericTypeParameters.length) {
      return false;
    }
    if (other.returnType != null && !other.returnType!.isTop) {
      if (returnType != null && !returnType!.isBottom) {
        return false;
      }
    }
    for (var i = 0; i < parameterTypes.length; ++i) {
      final param = parameterTypes[i];
      HTParameterType? otherParam;
      if (other.parameterTypes.length > i) {
        otherParam = other.parameterTypes[i];
      }
      if (!param.isOptional && !param.isVariadic) {
        if (otherParam == null ||
            otherParam.isOptional != param.isOptional ||
            otherParam.isVariadic != param.isVariadic ||
            otherParam.isNamed != param.isNamed ||
            (otherParam.declType.isNotA(param.declType))) {
          return false;
        }
      }
    }
    return true;
  }
}
