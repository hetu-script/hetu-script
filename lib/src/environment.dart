import 'errors.dart';
import 'token.dart';
import 'object.dart';
import 'constants.dart';

class VarWrapper {
  String type;
  HetuObject value;

  VarWrapper(this.type, {this.value}) {
    value ??= HetuObject.Null;
  }
}

class Environment {
  final Map<String, VarWrapper> _variables = {};

  Environment _enclosing;
  Environment get enclosing => _enclosing;

  Environment();

  Environment.enclose(Environment env) {
    _enclosing = env;
  }

  Environment upper(int distance) {
    var environment = this;
    for (var i = 0; i < distance; i++) {
      environment = environment.enclosing;
    }

    return environment;
  }

  HetuObject getByName(String name) {
    if (_variables.containsKey(name)) {
      return _variables[name].value;
    }

    if (enclosing != null) return enclosing.getByName(name);

    throw HetuErrorSymbolNotFound(name);
  }

  HetuObject getByToken(Token token) {
    if (_variables.containsKey(token.text)) {
      return _variables[token.text].value;
    }

    if (enclosing != null) return enclosing.getByToken(token);

    throw HetuErrorSymbolNotFound(token.text, token.lineNumber, token.colNumber);
  }

  HetuObject searchByName(int distance, String name) => upper(distance).getByName(name);

  HetuObject searchByToken(int distance, Token token) => upper(distance).getByToken(token);

  /// 直接以字符串形式定义一个变量，通常用于绑定系统功能等
  void define(String varname, String type, {HetuObject value}) {
    if (!_variables.containsKey(varname)) {
      if ((type == Constants.Dynamic) || ((value != null) && (type == value.type)) || (value == null)) {
        _variables[varname] = VarWrapper(type, value: value);
      } else {
        throw HetuError('(Environment) Value type [${value.type}] doesn\'t match declared type [${type}].');
      }
    } else {
      throw HetuError(
        '(Environment) Variable [${varname}] is already declared.',
      );
    }
  }

  /// 以Token定义一个变量，通常用这个来声明变量，遇到错误会输出Token的行号
  void declare(Token name, String type, {HetuObject value}) {
    if (!_variables.containsKey(name.text)) {
      if ((type == Constants.Dynamic) || ((value != null) && (type == value.type)) || (value == null)) {
        _variables[name.text] = VarWrapper(type, value: value);
      } else {
        throw HetuError('(Environment) Value type [${value.type}] doesn\'t match declared type [${type}].'
            ' [${name.lineNumber}, ${name.colNumber}].');
      }
    } else {
      throw HetuError('(Environment) Variable [${name.text}] is already declared.'
          ' [${name.lineNumber}, ${name.colNumber}].');
    }
  }

  /// 向一个已经声明的变量赋值
  void assign(Token name, HetuObject value) {
    if (_variables.containsKey(name.text)) {
      var variableType = _variables[name.text].type;
      if ((variableType == Constants.Dynamic) || (variableType == value.type)) {
        // 直接改写wrapper里面的值就行，不用重新生成wrapper
        _variables[name.text].value = value;
      } else {
        throw HetuError(
            '(Environment) Assigned value type [${value.type}] doesn\'t match declared type [${variableType}].'
            ' [${name.lineNumber}, ${name.colNumber}].');
      }
    } else if (enclosing != null) {
      enclosing.assign(name, value);
    } else {
      throw HetuErrorSymbolNotFound(name.text, name.lineNumber, name.colNumber);
    }
  }

  void assignAt(int distance, Token name, dynamic value) => upper(distance).assign(name, value);

  bool contains(String key) => _variables.containsKey(key);

  void clear() => _variables.clear();
}
