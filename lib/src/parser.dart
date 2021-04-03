import 'token.dart';
import 'lexicon.dart';
import 'errors.dart';

/// 负责对Token列表进行语法分析并生成语句列表
///
/// 语法定义如下
///
/// <程序>    ::=   <导入语句> | <变量声明>
///
/// <变量声明>      ::=   <变量声明> | <函数定义> | <类定义>
///
/// <语句块>    ::=   "{" <语句> { <语句> } "}"
///
/// <语句>      ::=   <声明> | <表达式> ";"
///
/// <表达式>    ::=   <标识符> | <单目> | <双目> | <三目>
///
/// <运算符>    ::=   <运算符>
abstract class Parser {
  late List<Token> tokens;

  void addTokens(List<Token> tokens) {
    tokPos = 0;
    this.tokens = tokens;
    _curLine = 0;
    _curColumn = 0;
  }

  static int internalVarIndex = 0;

  int _curLine = 0;
  int _curColumn = 0;
  int get curLine => _curLine;
  int get curColumn => _curColumn;
  String? get curModuleUniqueKey;

  var tokPos = 0;

  /// 检查包括当前Token在内的接下来数个Token是否符合类型要求
  ///
  /// 根据是否符合预期，返回 boolean
  ///
  /// 如果consume为true，则在符合要求时向前移动Token指针
  bool expect(List<String> tokTypes, {bool consume = false}) {
    for (var i = 0; i < tokTypes.length; ++i) {
      if (peek(i).type != tokTypes[i]) {
        return false;
      }
    }
    if (consume) {
      advance(tokTypes.length);
    }
    return true;
  }

  /// 如果当前token符合要求则前进一步，然后返回之前的token，否则抛出异常
  Token match(String tokenType) {
    if (curTok.type == tokenType) {
      return advance(1);
    }

    throw HTErrorExpected(tokenType, curTok.lexeme);
  }

  /// 前进指定距离，返回原先位置的Token
  Token advance(int distance) {
    tokPos += distance;
    _curLine = curTok.line;
    _curColumn = curTok.column;
    return peek(-distance);
  }

  /// 获得相对于目前位置一定距离的Token，不改变目前位置
  Token peek(int pos) {
    if ((tokPos + pos) < tokens.length) {
      return tokens[tokPos + pos];
    } else {
      return Token(HTLexicon.endOfFile, curModuleUniqueKey!, -1, -1);
    }
  }

  /// 获得当前Token
  Token get curTok => peek(0);
}
