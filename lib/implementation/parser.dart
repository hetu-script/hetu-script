import '../implementation/type.dart';
import '../common/constants.dart';
import '../common/errors.dart';
import 'token.dart';
import 'lexicon.dart';
import 'lexer.dart';

class _ParseTypeResult {
  HTType parsedType;
  int pos;

  _ParseTypeResult(this.parsedType, this.pos);
}

/// Configuration of [Parser]
class ParserConfig {
  final CodeType codeType;
  final bool reload;
  final bool bundle;
  final bool lineInfo;

  const ParserConfig(
      {this.codeType = CodeType.module,
      this.reload = false,
      this.bundle = false,
      this.lineInfo = true});
}

/// Parse a token list and generate source code,
/// [HTAstParser] and [HTCompiler] implements this class
abstract class Parser {
  static var anonymousFuncIndex = 0;

  static _ParseTypeResult _parseTypeFromTokens(List<Token> tokens) {
    final typeName = tokens.first.lexeme;
    var pos = 1;
    var type_args = <HTType>[];

    while (pos < tokens.length) {
      if (tokens[pos].type == HTLexicon.angleLeft) {
        pos++;
        while (
            (pos < tokens.length) && tokens[pos].type != HTLexicon.angleRight) {
          final result = _parseTypeFromTokens(tokens.sublist(pos));
          type_args.add(result.parsedType);
          pos = result.pos;
          if (tokens[pos].type != HTLexicon.angleRight) {
            if (tokens[pos].type == HTLexicon.comma) {
              ++pos;
            } else {
              throw HTError.unexpected(HTLexicon.comma, tokens[pos].lexeme);
            }
          }
        }
        if (tokens[pos].type != HTLexicon.angleRight) {
          throw HTError.unexpected(HTLexicon.angleRight, tokens[pos].lexeme);
        } else {
          break;
        }
      } else {
        throw HTError.unexpected(HTLexicon.angleLeft, tokens[pos].lexeme);
      }
    }

    final parsedType = HTType(typeName, typeArgs: type_args);
    return _ParseTypeResult(parsedType, pos);
  }

  static HTType parseType(String typeString) {
    final tokens = Lexer().lex(typeString, SemanticType.typeExpression);
    if (tokens.isEmpty) {
      throw HTError.emptyString(SemanticType.typeExpression);
    }

    if (tokens.first.type != HTLexicon.identifier) {
      throw HTError.unexpected(HTLexicon.identifier, tokens.first.lexeme);
    }

    final parseResult = _parseTypeFromTokens(tokens);

    return parseResult.parsedType;
  }

  late ParserConfig config;

  int _curLine = 0;
  int _curColumn = 0;
  int get curLine => _curLine;
  int get curColumn => _curColumn;
  String? get curModuleFullName;

  var tokPos = 0;

  final List<Token> _tokens = [];

  void addTokens(List<Token> tokens) {
    tokPos = 0;
    _tokens.clear();
    _tokens.addAll(tokens);
    _curLine = 0;
    _curColumn = 0;
  }

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

    throw HTError.unexpected(tokenType, curTok.lexeme);
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
    if ((tokPos + pos) < _tokens.length) {
      return _tokens[tokPos + pos];
    } else {
      return Token(HTLexicon.endOfFile, curModuleFullName!, -1, -1);
    }
  }

  /// 获得当前Token
  Token get curTok => peek(0);
}
