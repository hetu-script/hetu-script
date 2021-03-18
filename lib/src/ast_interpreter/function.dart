import 'class.dart';
import 'namespace.dart';
import '../errors.dart';
import 'type.dart';
import '../lexicon.dart';
import 'expression.dart';
import 'ast_interpreter.dart';

class HTFunctionType extends HTTypeId {
  final HTTypeId returnType;
  final List<HTTypeId> paramsTypes;

  HTFunctionType(this.returnType, {List<HTTypeId> arguments = const [], this.paramsTypes = const []})
      : super(HTLexicon.function, arguments: arguments);

  @override
  String toString() {
    var result = StringBuffer();
    result.write('$id');
    if (arguments.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < arguments.length; ++i) {
        result.write(arguments[i]);
        if ((arguments.length > 1) && (i != arguments.length - 1)) result.write(', ');
      }
      result.write('>');
    }

    result.write('(');

    for (final param in paramsTypes) {
      result.write(param.id);
      //if (param.initializer != null)
      if (paramsTypes.length > 1) result.write(', ');
    }
    result.write('): ' + returnType.toString());
    return result.toString();
  }
}

class HTFunction with HTType, ASTInterpreterRef {
  static final callStack = <String>[];

  HTNamespace declContext;
  late HTNamespace _closure;
  //HTNamespace _save;
  String get id => funcStmt.id?.lexeme ?? '';
  String get internalName => funcStmt.internalName;

  final FuncDeclaration funcStmt;

  late final HTFunctionType _typeid;
  @override
  HTTypeId get typeid => _typeid;

  final bool isExtern;

  HTFunction(this.funcStmt, this.declContext, HTInterpreter interpreter,
      {List<HTTypeId> typeArgs = const [], this.isExtern = false}) {
    //_save = _closure = closure;
    this.interpreter = interpreter;

    var paramsTypes = <HTTypeId>[];
    for (final param in funcStmt.params) {
      paramsTypes.add(param.declType);
    }
    _typeid = HTFunctionType(funcStmt.returnType, arguments: typeArgs, paramsTypes: paramsTypes);
  }

  @override
  String toString() {
    var result = StringBuffer();
    result.write('${HTLexicon.function}');
    result.write(' $id');
    if (typeid.arguments.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < typeid.arguments.length; ++i) {
        result.write(typeid.arguments[i]);
        if ((typeid.arguments.length > 1) && (i != typeid.arguments.length - 1)) result.write(', ');
      }
      result.write('>');
    }

    result.write('(');

    for (final param in funcStmt.params) {
      if (param.isVariadic) {
        result.write(HTLexicon.varargs + ' ');
      }
      result.write(param.id.lexeme + ': ' + (param.declType.toString()));
      //if (param.initializer != null)
      if (funcStmt.params.length > 1) result.write(', ');
    }
    result.write('): ' + funcStmt.returnType.toString());
    return result.toString();
  }

  dynamic call(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HTInstance? instance}) {
    callStack.add(internalName);

    if (positionalArgs.length < funcStmt.arity ||
        (positionalArgs.length > funcStmt.params.length && !funcStmt.isVariadic)) {
      throw HTErrorArity(id, positionalArgs.length, funcStmt.arity);
    }

    dynamic result;
    try {
      if (funcStmt.definition != null) {
        //_save = _closure;
        //assert(closure != null);
        // 函数每次在调用时，才生成对应的作用域
        if (instance != null) {
          _closure = HTNamespace(interpreter, id: '${instance.id}.$id', closure: instance);
          _closure.define(HTLexicon.THIS, declType: instance.typeid, isImmutable: true);
        } else {
          _closure = HTNamespace(interpreter, id: '$id', closure: declContext);
        }

        for (var i = 0; i < funcStmt.params.length; ++i) {
          var param = funcStmt.params[i];

          if (funcStmt.params[i].isOptional &&
              (i >= positionalArgs.length) &&
              (funcStmt.params[i].initializer != null)) {
            positionalArgs.add(interpreter.visitASTNode(funcStmt.params[i].initializer!));
          } else if (funcStmt.params[i].isNamed &&
              (namedArgs[funcStmt.params[i].id.lexeme] == null) &&
              (funcStmt.params[i].initializer != null)) {
            namedArgs[funcStmt.params[i].id.lexeme] = interpreter.visitASTNode(funcStmt.params[i].initializer!);
          }

          var arg;
          if (!param.isNamed) {
            arg = positionalArgs[i];
          } else {
            arg = namedArgs[param.id as String];
          }
          final arg_type_decl = param.declType;

          if (!param.isVariadic) {
            var arg_type = interpreter.typeof(arg);
            if (arg_type.isNotA(arg_type_decl)) {
              throw HTErrorArgType(arg.toString(), arg_type.toString(), arg_type_decl.toString());
            }
            _closure.define(param.id.lexeme, declType: arg_type_decl, value: arg);
          } else {
            var varargs = [];
            for (var j = i; j < positionalArgs.length; ++j) {
              arg = positionalArgs[j];
              var arg_type = interpreter.typeof(arg);
              if (arg_type.isNotA(arg_type_decl)) {
                throw HTErrorArgType(arg.toString(), arg_type.toString(), arg_type_decl.toString());
              }
              varargs.add(arg);
            }
            _closure.define(param.id.lexeme, declType: HTTypeId.list, value: varargs);
            break;
          }
        }

        result = interpreter.executeBlock(funcStmt.definition!, _closure);

        //_closure = _save;
      } else {
        throw HTErrorMissingFuncDef(id);
      }
    } catch (returnValue) {
      if ((returnValue is HTError) || (returnValue is Exception) || (returnValue is Error)) {
        rethrow;
      }

      var returned_type = interpreter.typeof(returnValue);

      if (returned_type.isNotA(funcStmt.returnType)) {
        throw HTErrorReturnType(returned_type.toString(), id, funcStmt.returnType.toString());
      }

      callStack.removeLast();

      if (returnValue is NullThrownError) return null;

      //_closure = _save;
      return returnValue;
    }

    callStack.removeLast();
    // 如果函数体中没有直接return，则会返回最后一个语句的值
    return result;
  }
}
