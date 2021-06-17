import '../source/source.dart';
import '../error/error.dart';
import '../grammar/semantic.dart';
import '../grammar/token.dart';

class ParserConfig {
  final SourceType sourceType;
  final bool reload;

  const ParserConfig(
      {this.sourceType = SourceType.module, this.reload = false});
}

abstract class AbstractParser {
  static var anonymousFuncIndex = 0;

  ParserConfig config;

  int _curLine = 0;
  int _curColumn = 0;
  int get curLine => _curLine;
  int get curColumn => _curColumn;

  /// The module current processing, used in error message.
  String get curModuleFullName;

  String get curLibraryName;

  var tokPos = 0;

  final List<Token> _tokens = [];

  AbstractParser(this.config);

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
      return Token(SemanticNames.endOfFile, -1, -1);
    }
  }

  /// 获得当前Token
  Token get curTok => peek(0);
}
