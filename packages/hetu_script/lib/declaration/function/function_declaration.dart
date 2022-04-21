import 'package:meta/meta.dart';

import '../../grammar/constant.dart';
import '../../type/type.dart';
import '../../type/function.dart';
import '../../source/source.dart';
import '../type/abstract_type_declaration.dart';
import '../declaration.dart';
import '../namespace/declaration_namespace.dart';
import 'abstract_parameter.dart';
import '../generic/generic_type_parameter.dart';
import '../../value/entity.dart';

class HTFunctionDeclaration extends HTDeclaration
    implements HTAbstractTypeDeclaration {
  final String internalName;

  final FunctionCategory category;

  final String? externalTypeId;

  @override
  final List<HTGenericTypeParameter> genericTypeParameters;

  /// Wether to check params when called
  /// A function like:
  ///   ```
  ///     fun { return 42 }
  ///   ```
  /// will accept any params, while a function:
  ///   ```
  ///     fun () { return 42 }
  ///   ```
  /// will accept 0 params
  final bool hasParamDecls;

  /// Holds declarations of all parameters.
  final Map<String, HTAbstractParameter> _paramDecls;

  /// Holds declarations of all parameters.
  Map<String, HTAbstractParameter>? _resolvedParamDecls;

  Map<String, HTAbstractParameter> get paramDecls =>
      _resolvedParamDecls ?? _paramDecls;

  HTType get returnType => declType.returnType;

  final HTFunctionType declType;

  final bool isField;

  final bool isAbstract;

  final bool isVariadic;

  final int minArity;

  final int maxArity;

  HTDeclarationNamespace? namespace;

  HTEntity? instance;

  bool _isResolved = false;
  @override
  bool get isResolved => _isResolved;

  HTFunctionDeclaration(this.internalName,
      {String? id,
      String? classId,
      HTDeclarationNamespace? closure,
      HTSource? source,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isTopLevel = false,
      this.category = FunctionCategory.normal,
      this.externalTypeId,
      this.genericTypeParameters = const [],
      this.hasParamDecls = true,
      Map<String, HTAbstractParameter> paramDecls = const {},
      required this.declType,
      this.isField = false,
      this.isAbstract = false,
      this.isVariadic = false,
      this.minArity = 0,
      this.maxArity = 0,
      this.namespace})
      : _paramDecls = paramDecls,
        super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isTopLevel: isTopLevel);

  @override
  @mustCallSuper
  void resolve() {
    if (_isResolved) {
      return;
    }
    for (final param in paramDecls.values) {
      param.resolve();
    }
    _isResolved = true;
  }

  @override
  HTFunctionDeclaration clone() => HTFunctionDeclaration(internalName,
      id: id,
      classId: classId,
      closure: closure,
      source: source,
      isExternal: isExternal,
      isStatic: isStatic,
      isConst: isConst,
      isTopLevel: isTopLevel,
      category: category,
      externalTypeId: externalTypeId,
      genericTypeParameters: genericTypeParameters,
      paramDecls: paramDecls,
      declType: declType,
      isField: isField,
      isAbstract: isAbstract,
      isVariadic: isVariadic,
      minArity: minArity,
      maxArity: maxArity,
      namespace: namespace);
}
