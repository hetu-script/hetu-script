import 'parser.dart';
import 'token.dart';
import '../lexicon/lexicon2.dart';
import '../lexicon/lexicon_default_impl.dart';
import '../error/error.dart';
import '../lexer/lexer.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../grammar/constant.dart';
import '../source/source.dart';
import '../declaration/class/class_declaration.dart';
import '../ast/ast.dart';
import '../comment/comment.dart';
import '../parser/parser.dart';

/// Default semantics implementation used by Hetu.
class HTDefaultParser extends HTParser {
  @override
  String get name => 'default';

  /// Lexicon definition used by this parser.
  late final HTLexicon lexicon;

  late final HTLexer _lexer;

  HTDefaultParser() : lexicon = HTDefaultLexicon() {
    _lexer = HTLexer(lexicon: lexicon);
  }

  // All import decl in this list must have non-null [fromPath]
  late List<ImportExportDecl> _currentModuleImports;

  List<Comment> _currentPrecedingComments = [];

  HTClassDeclaration? _currentClass;
  FunctionCategory? _currentFunctionCategory;
  String? _currentStructId;

  var _leftValueLegality = false;
  final List<Map<String, String>> _markedSymbolsList = [];

  bool _hasUserDefinedConstructor = false;

  HTSource? _currentSource;

  bool get _isWithinModuleNamespace {
    if (_currentFunctionCategory != null) {
      return false;
    } else if (_currentSource != null) {
      if (_currentSource!.type == HTResourceType.hetuModule) {
        return true;
      }
    }
    return false;
  }

  @override
  List<ASTNode> parseToken(Token token,
      {HTSource? source, ParseStyle? style, ParserConfig? config}) {
    // create new list of errors here, old error list is still usable
    errors = <HTError>[];
    final nodes = <ASTNode>[];
    setTokens(token);
    _currentSource = source;
    currrentFileName = source?.fullName;
    late ParseStyle parseStyle;
    if (style != null) {
      parseStyle = style;
    } else {
      if (_currentSource != null) {
        final sourceType = _currentSource!.type;
        if (sourceType == HTResourceType.hetuModule) {
          parseStyle = ParseStyle.module;
        } else if (sourceType == HTResourceType.hetuScript ||
            sourceType == HTResourceType.hetuLiteralCode) {
          parseStyle = ParseStyle.script;
        } else if (sourceType == HTResourceType.hetuValue) {
          parseStyle = ParseStyle.expression;
        } else {
          return nodes;
        }
      } else {
        parseStyle = ParseStyle.script;
      }
    }
    while (curTok.type != Semantic.endOfFile) {
      final stmt = _parseStmt(sourceType: parseStyle);
      if (stmt != null) {
        if (stmt is ASTEmptyLine && parseStyle == ParseStyle.expression) {
          continue;
        }
        nodes.add(stmt);
      }
    }
    if (nodes.isEmpty) {
      final empty = ASTEmptyLine(
          source: _currentSource,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.end);
      empty.precedingComments = _currentPrecedingComments;
      _currentPrecedingComments = [];
      nodes.add(empty);
    }
    return nodes;
  }

  @override
  ASTSource parseSource(HTSource source) {
    currrentFileName = source.fullName;
    _currentClass = null;
    _currentFunctionCategory = null;
    _currentModuleImports = <ImportExportDecl>[];
    final tokens = _lexer.lex(source.content);
    final nodes = parseToken(tokens, source: source);
    final result = ASTSource(
        nodes: nodes,
        source: source,
        imports: _currentModuleImports,
        errors: errors); // copy the list);
    return result;
  }

  bool _handlePrecedingComment() {
    bool handled = false;
    while (curTok is TokenComment) {
      handled = true;
      final comment = Comment.fromToken(curTok as TokenComment);
      _currentPrecedingComments.add(comment);
      advance();
    }
    return handled;
  }

  bool _handleTrailingComment(ASTNode expr) {
    if (curTok is TokenComment) {
      final tokenComment = curTok as TokenComment;
      if (tokenComment.isTrailing) {
        advance();
        expr.trailingComment = Comment.fromToken(tokenComment);
      }
      return true;
    }
    return false;
  }

  ASTNode? _parseStmt({ParseStyle sourceType = ParseStyle.functionDefinition}) {
    if (_handlePrecedingComment()) {
      return null;
    }

    final precedingComments = _currentPrecedingComments;
    _currentPrecedingComments = [];

    if (curTok is TokenEmptyLine) {
      final empty = advance();
      final emptyStmt = ASTEmptyLine(
          line: empty.line, column: empty.column, offset: empty.offset);
      emptyStmt.precedingComments = precedingComments;
      return emptyStmt;
    }

    ASTNode stmt;

    switch (sourceType) {
      case ParseStyle.script:
        if (curTok.lexeme == lexicon.kImport) {
          stmt = _parseImportDecl();
        } else if (curTok.lexeme == lexicon.kExport) {
          stmt = _parseExportStmt();
        } else if (curTok.lexeme == lexicon.kType) {
          stmt = _parseTypeAliasDecl();
        } else {
          switch (curTok.type) {
            case lexicon.kExternal:
              advance();
              switch (curTok.type) {
                case lexicon.kAbstract:
                  advance();
                  stmt = _parseClassDecl(
                      isAbstract: true, isExternal: true, isTopLevel: true);
                  break;
                case lexicon.kClass:
                  stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
                  break;
                case lexicon.kEnum:
                  stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
                  break;
                case lexicon.kVar:
                case lexicon.kFinal:
                case lexicon.kConst:
                case lexicon.kLate:
                  final err = HTError.externalVar(
                      filename: currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = ASTEmptyLine(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                  break;
                case lexicon.kFun:
                  stmt = _parseFunction(isExternal: true, isTopLevel: true);
                  break;
                default:
                  final err = HTError.unexpected(
                      Semantic.declStmt, curTok.lexeme,
                      filename: currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = ASTEmptyLine(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
              }
              break;
            case lexicon.kAbstract:
              advance();
              stmt = _parseClassDecl(
                  isAbstract: true, isTopLevel: true, lateResolve: false);
              break;
            case lexicon.kClass:
              stmt = _parseClassDecl(isTopLevel: true, lateResolve: false);
              break;
            case lexicon.kEnum:
              stmt = _parseEnumDecl(isTopLevel: true);
              break;
            case lexicon.kNamespace:
              stmt = _parseNamespaceDecl(isTopLevel: true);
              break;
            case lexicon.kVar:
              if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
                stmt = _parseDestructuringDecl(isMutable: true);
              } else {
                stmt = _parseVarDecl(isMutable: true, isTopLevel: true);
              }
              break;
            case lexicon.kFinal:
              if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
                stmt = _parseDestructuringDecl();
              } else {
                stmt = _parseVarDecl(isTopLevel: true);
              }
              break;
            case lexicon.kLate:
              stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
              break;
            case lexicon.kConst:
              stmt = _parseVarDecl(isConst: true, isTopLevel: true);
              break;
            case lexicon.kFun:
              if (expect([lexicon.kFun, Semantic.identifier]) ||
                  expect([
                    lexicon.kFun,
                    lexicon.externalFunctionTypeDefStart,
                    Semantic.identifier,
                    lexicon.externalFunctionTypeDefEnd,
                    Semantic.identifier
                  ])) {
                stmt = _parseFunction(isTopLevel: true);
              } else {
                stmt = _parseFunction(
                    category: FunctionCategory.literal, isTopLevel: true);
              }
              break;
            case lexicon.kAsync:
              if (expect([lexicon.kAsync, Semantic.identifier]) ||
                  expect([
                    lexicon.kFun,
                    lexicon.externalFunctionTypeDefStart,
                    Semantic.identifier,
                    lexicon.externalFunctionTypeDefEnd,
                    Semantic.identifier
                  ])) {
                stmt = _parseFunction(isAsync: true, isTopLevel: true);
              } else {
                stmt = _parseFunction(
                    category: FunctionCategory.literal,
                    isAsync: true,
                    isTopLevel: true);
              }
              break;
            case lexicon.kStruct:
              stmt = _parseStructDecl(isTopLevel: true, lateInitialize: false);
              break;
            case lexicon.kDelete:
              stmt = _parseDeleteStmt();
              break;
            case lexicon.kIf:
              stmt = _parseIf();
              break;
            case lexicon.kWhile:
              stmt = _parseWhileStmt();
              break;
            case lexicon.kDo:
              stmt = _parseDoStmt();
              break;
            case lexicon.kFor:
              stmt = _parseForStmt();
              break;
            case lexicon.kWhen:
              stmt = _parseWhen();
              break;
            case lexicon.kAssert:
              stmt = _parseAssertStmt();
              break;
            case lexicon.kThrow:
              stmt = _parseThrowStmt();
              break;
            default:
              stmt = _parseExprStmt();
          }
        }
        break;
      case ParseStyle.module:
        if (curTok.lexeme == lexicon.kImport) {
          stmt = _parseImportDecl();
        } else if (curTok.lexeme == lexicon.kExport) {
          stmt = _parseExportStmt();
        } else if (curTok.lexeme == lexicon.kType) {
          stmt = _parseTypeAliasDecl(isTopLevel: true);
        } else {
          switch (curTok.type) {
            case lexicon.kNamespace:
              stmt = _parseNamespaceDecl(isTopLevel: true);
              break;
            case lexicon.kExternal:
              advance();
              switch (curTok.type) {
                case lexicon.kAbstract:
                  advance();
                  if (curTok.type != lexicon.kClass) {
                    final err = HTError.unexpected(
                        Semantic.classDeclaration, curTok.lexeme,
                        filename: currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance();
                    stmt = ASTEmptyLine(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                  } else {
                    stmt = _parseClassDecl(
                        isAbstract: true, isExternal: true, isTopLevel: true);
                  }
                  break;
                case lexicon.kClass:
                  stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
                  break;
                case lexicon.kEnum:
                  stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
                  break;
                case lexicon.kFun:
                  stmt = _parseFunction(isExternal: true, isTopLevel: true);
                  break;
                case lexicon.kVar:
                case lexicon.kFinal:
                case lexicon.kLate:
                case lexicon.kConst:
                  final err = HTError.externalVar(
                      filename: currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = ASTEmptyLine(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                  break;
                default:
                  final err = HTError.unexpected(
                      Semantic.declStmt, curTok.lexeme,
                      filename: currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = ASTEmptyLine(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
              }
              break;
            case lexicon.kAbstract:
              advance();
              stmt = _parseClassDecl(isAbstract: true, isTopLevel: true);
              break;
            case lexicon.kClass:
              stmt = _parseClassDecl(isTopLevel: true);
              break;
            case lexicon.kEnum:
              stmt = _parseEnumDecl(isTopLevel: true);
              break;
            case lexicon.kVar:
              stmt = _parseVarDecl(
                  isMutable: true, isTopLevel: true, lateInitialize: true);
              break;
            case lexicon.kFinal:
              stmt = _parseVarDecl(lateInitialize: true, isTopLevel: true);
              break;
            case lexicon.kLate:
              stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
              break;
            case lexicon.kConst:
              stmt = _parseVarDecl(isConst: true, isTopLevel: true);
              break;
            case lexicon.kFun:
              stmt = _parseFunction(isTopLevel: true);
              break;
            case lexicon.kStruct:
              stmt = _parseStructDecl(isTopLevel: true);
              break;
            default:
              final err = HTError.unexpected(Semantic.declStmt, curTok.lexeme,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
          }
        }
        break;
      case ParseStyle.namespace:
        if (curTok.lexeme == lexicon.kType) {
          stmt = _parseTypeAliasDecl();
        } else {
          switch (curTok.type) {
            case lexicon.kNamespace:
              stmt = _parseNamespaceDecl();
              break;
            case lexicon.kExternal:
              advance();
              switch (curTok.type) {
                case lexicon.kAbstract:
                  advance();
                  if (curTok.type != lexicon.kClass) {
                    final err = HTError.unexpected(
                        Semantic.classDeclaration, curTok.lexeme,
                        filename: currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance();
                    stmt = ASTEmptyLine(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                  } else {
                    stmt = _parseClassDecl(isAbstract: true, isExternal: true);
                  }
                  break;
                case lexicon.kClass:
                  stmt = _parseClassDecl(isExternal: true);
                  break;
                case lexicon.kEnum:
                  stmt = _parseEnumDecl(isExternal: true);
                  break;
                case lexicon.kFun:
                  stmt = _parseFunction(isExternal: true);
                  break;
                case lexicon.kVar:
                case lexicon.kFinal:
                case lexicon.kLate:
                case lexicon.kConst:
                  final err = HTError.externalVar(
                      filename: currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = ASTEmptyLine(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                  break;
                default:
                  final err = HTError.unexpected(
                      Semantic.declStmt, curTok.lexeme,
                      filename: currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = ASTEmptyLine(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
              }
              break;
            case lexicon.kAbstract:
              advance();
              stmt = _parseClassDecl(
                  isAbstract: true, lateResolve: _isWithinModuleNamespace);
              break;
            case lexicon.kClass:
              stmt = _parseClassDecl(lateResolve: _isWithinModuleNamespace);
              break;
            case lexicon.kEnum:
              stmt = _parseEnumDecl();
              break;
            case lexicon.kVar:
              stmt = _parseVarDecl(
                  isMutable: true, lateInitialize: _isWithinModuleNamespace);
              break;
            case lexicon.kFinal:
              stmt = _parseVarDecl(lateInitialize: _isWithinModuleNamespace);
              break;
            case lexicon.kConst:
              stmt = _parseVarDecl(isConst: true);
              break;
            case lexicon.kFun:
              stmt = _parseFunction();
              break;
            case lexicon.kStruct:
              stmt = _parseStructDecl();
              break;
            default:
              final err = HTError.unexpected(Semantic.declStmt, curTok.lexeme,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
          }
        }
        break;
      case ParseStyle.classDefinition:
        final isOverrided = expect([lexicon.kOverride], consume: true);
        final isExternal = expect([lexicon.kExternal], consume: true) ||
            (_currentClass?.isExternal ?? false);
        final isStatic = expect([lexicon.kStatic], consume: true);
        if (curTok.lexeme == lexicon.kType) {
          if (isExternal) {
            final err = HTError.external(Semantic.typeAliasDeclaration,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors?.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: _currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else {
            stmt = _parseTypeAliasDecl();
          }
        } else {
          switch (curTok.type) {
            case lexicon.kVar:
              stmt = _parseVarDecl(
                  classId: _currentClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isMutable: true,
                  isStatic: isStatic,
                  lateInitialize: true);
              break;
            case lexicon.kFinal:
              stmt = _parseVarDecl(
                  classId: _currentClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic,
                  lateInitialize: true);
              break;
            case lexicon.kLate:
              stmt = _parseVarDecl(
                  classId: _currentClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic,
                  lateFinalize: true);
              break;
            case lexicon.kConst:
              if (isStatic) {
                stmt = _parseVarDecl(isConst: true, classId: _currentClass?.id);
              } else {
                final err = HTError.external(Semantic.typeAliasDeclaration,
                    filename: currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = ASTEmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              }
              break;
            case lexicon.kFun:
              stmt = _parseFunction(
                  category: FunctionCategory.method,
                  classId: _currentClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic);
              break;
            case lexicon.kAsync:
              if (isExternal) {
                final err = HTError.external(Semantic.asyncFunction,
                    filename: currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = ASTEmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else {
                stmt = _parseFunction(
                    category: FunctionCategory.method,
                    classId: _currentClass?.id,
                    isAsync: true,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic);
              }
              break;
            case lexicon.kGet:
              stmt = _parseFunction(
                  category: FunctionCategory.getter,
                  classId: _currentClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic);
              break;
            case lexicon.kSet:
              stmt = _parseFunction(
                  category: FunctionCategory.setter,
                  classId: _currentClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic);
              break;
            case lexicon.kConstruct:
              if (isStatic) {
                final err = HTError.unexpected(
                    Semantic.declStmt, lexicon.kConstruct,
                    filename: currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = ASTEmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else if (isExternal && !_currentClass!.isExternal) {
                final err = HTError.external(Semantic.ctorFunction,
                    filename: currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = ASTEmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else {
                stmt = _parseFunction(
                  category: FunctionCategory.constructor,
                  classId: _currentClass?.id,
                  isExternal: isExternal,
                );
              }
              break;
            case lexicon.kFactory:
              if (isStatic) {
                final err = HTError.unexpected(
                    Semantic.declStmt, lexicon.kConstruct,
                    filename: currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = ASTEmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else if (isExternal && !_currentClass!.isExternal) {
                final err = HTError.external(Semantic.factory,
                    filename: currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = ASTEmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else {
                stmt = _parseFunction(
                  category: FunctionCategory.factoryConstructor,
                  classId: _currentClass?.id,
                  isExternal: isExternal,
                  isStatic: true,
                );
              }
              break;
            default:
              final err = HTError.unexpected(Semantic.declStmt, curTok.lexeme,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
          }
        }
        break;
      case ParseStyle.structDefinition:
        final isExternal = expect([lexicon.kExternal], consume: true);
        final isStatic = expect([lexicon.kStatic], consume: true);
        switch (curTok.type) {
          case lexicon.kVar:
            stmt = _parseVarDecl(
                classId: _currentStructId,
                isField: true,
                isExternal: isExternal,
                isMutable: true,
                isStatic: isStatic,
                lateInitialize: true);
            break;
          case lexicon.kFinal:
            stmt = _parseVarDecl(
                classId: _currentStructId,
                isField: true,
                isExternal: isExternal,
                isStatic: isStatic,
                lateInitialize: true);
            break;
          case lexicon.kFun:
            stmt = _parseFunction(
                category: FunctionCategory.method,
                classId: _currentStructId,
                isExternal: isExternal,
                isField: true,
                isStatic: isStatic);
            break;
          case lexicon.kAsync:
            if (isExternal) {
              final err = HTError.external(Semantic.asyncFunction,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              stmt = _parseFunction(
                  category: FunctionCategory.method,
                  classId: _currentStructId,
                  isAsync: true,
                  isField: true,
                  isExternal: isExternal,
                  isStatic: isStatic);
            }
            break;
          case lexicon.kGet:
            stmt = _parseFunction(
                category: FunctionCategory.getter,
                classId: _currentStructId,
                isField: true,
                isExternal: isExternal,
                isStatic: isStatic);
            break;
          case lexicon.kSet:
            stmt = _parseFunction(
                category: FunctionCategory.setter,
                classId: _currentStructId,
                isField: true,
                isExternal: isExternal,
                isStatic: isStatic);
            break;
          case lexicon.kConstruct:
            if (isStatic) {
              final err = HTError.unexpected(
                  Semantic.declStmt, lexicon.kConstruct,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else if (isExternal) {
              final err = HTError.external(Semantic.ctorFunction,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              stmt = _parseFunction(
                  category: FunctionCategory.constructor,
                  classId: _currentStructId,
                  isExternal: isExternal,
                  isField: true);
            }
            break;
          default:
            final err = HTError.unexpected(Semantic.declStmt, curTok.lexeme,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors?.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: _currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
        }
        break;
      case ParseStyle.functionDefinition:
        switch (curTok.type) {
          case lexicon.kNamespace:
            stmt = _parseNamespaceDecl();
            break;
          case lexicon.kAbstract:
            advance();
            stmt = _parseClassDecl(isAbstract: true, lateResolve: false);
            break;
          case lexicon.kClass:
            stmt = _parseClassDecl(lateResolve: false);
            break;
          case lexicon.kEnum:
            stmt = _parseEnumDecl();
            break;
          case lexicon.kVar:
            if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
              stmt = _parseDestructuringDecl(isMutable: true);
            } else {
              stmt = _parseVarDecl(isMutable: true);
            }
            break;
          case lexicon.kFinal:
            if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
              stmt = _parseDestructuringDecl();
            } else {
              stmt = _parseVarDecl();
            }
            break;
          case lexicon.kLate:
            stmt = _parseVarDecl(lateFinalize: true);
            break;
          case lexicon.kConst:
            stmt = _parseVarDecl(isConst: true);
            break;
          case lexicon.kFun:
            if (expect([lexicon.kFun, Semantic.identifier]) ||
                expect([
                  lexicon.kFun,
                  lexicon.externalFunctionTypeDefStart,
                  Semantic.identifier,
                  lexicon.externalFunctionTypeDefEnd,
                  Semantic.identifier
                ])) {
              stmt = _parseFunction();
            } else {
              stmt = _parseFunction(category: FunctionCategory.literal);
            }
            break;
          case lexicon.kAsync:
            if (expect([lexicon.kAsync, Semantic.identifier]) ||
                expect([
                  lexicon.kFun,
                  lexicon.externalFunctionTypeDefStart,
                  Semantic.identifier,
                  lexicon.externalFunctionTypeDefEnd,
                  Semantic.identifier
                ])) {
              stmt = _parseFunction(isAsync: true);
            } else {
              stmt = _parseFunction(
                  category: FunctionCategory.literal, isAsync: true);
            }
            break;
          case lexicon.kStruct:
            stmt = _parseStructDecl(lateInitialize: false);
            break;
          case lexicon.kDelete:
            stmt = _parseDeleteStmt();
            break;
          case lexicon.kIf:
            stmt = _parseIf();
            break;
          case lexicon.kWhile:
            stmt = _parseWhileStmt();
            break;
          case lexicon.kDo:
            stmt = _parseDoStmt();
            break;
          case lexicon.kFor:
            stmt = _parseForStmt();
            break;
          case lexicon.kWhen:
            stmt = _parseWhen();
            break;
          case lexicon.kAssert:
            stmt = _parseAssertStmt();
            break;
          case lexicon.kThrow:
            stmt = _parseThrowStmt();
            break;
          case lexicon.kBreak:
            final keyword = advance();
            final hasEndOfStmtMark =
                expect([lexicon.endOfStatementMark], consume: true);
            stmt = BreakStmt(keyword,
                hasEndOfStmtMark: hasEndOfStmtMark,
                source: _currentSource,
                line: keyword.line,
                column: keyword.column,
                offset: keyword.offset,
                length: keyword.length);
            break;
          case lexicon.kContinue:
            final keyword = advance();
            final hasEndOfStmtMark =
                expect([lexicon.endOfStatementMark], consume: true);
            stmt = ContinueStmt(keyword,
                hasEndOfStmtMark: hasEndOfStmtMark,
                source: _currentSource,
                line: keyword.line,
                column: keyword.column,
                offset: keyword.offset,
                length: keyword.length);
            break;
          case lexicon.kReturn:
            if (_currentFunctionCategory != null &&
                _currentFunctionCategory != FunctionCategory.constructor) {
              stmt = _parseReturnStmt();
            } else {
              final err = HTError.outsideReturn(
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            }
            break;
          default:
            stmt = _parseExprStmt();
        }
        break;
      case ParseStyle.expression:
        stmt = _parseExpr();
    }

    stmt.precedingComments = precedingComments;

    if (curTok is TokenComment) {
      final token = advance() as TokenComment;
      if (token.isTrailing) {
        stmt.trailingComment = Comment.fromToken(token);
      }
    }

    return stmt;
  }

  AssertStmt _parseAssertStmt() {
    final keyword = match(lexicon.kAssert);
    match(lexicon.groupExprStart);
    final expr = _parseExpr();
    match(lexicon.groupExprEnd);
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
    final stmt = AssertStmt(expr,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: expr.end - keyword.offset);
    return stmt;
  }

  ThrowStmt _parseThrowStmt() {
    final keyword = match(lexicon.kThrow);
    final message = _parseExpr();
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
    final stmt = ThrowStmt(message,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: message.end - keyword.offset);
    return stmt;
  }

  /// Recursive descent parsing
  ///
  /// Assignment operator =, precedence 1, associativity right
  ASTNode _parseExpr() {
    _handlePrecedingComment();
    ASTNode? expr;
    final left = _parserTernaryExpr();
    if (lexicon.assignments.contains(curTok.type)) {
      final op = advance();
      final right = _parseExpr();
      expr = AssignExpr(left, op.lexeme, right,
          source: _currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else {
      expr = left;
    }

    expr.precedingComments = _currentPrecedingComments;
    _currentPrecedingComments = [];

    return expr;
  }

  /// Ternery operator: e1 ? e2 : e3, precedence 3, associativity right
  ASTNode _parserTernaryExpr() {
    var condition = _parseIfNullExpr();
    if (expect([lexicon.ternaryThen], consume: true)) {
      _leftValueLegality = false;
      final thenBranch = _parserTernaryExpr();
      match(lexicon.ternaryElse);
      final elseBranch = _parserTernaryExpr();
      condition = TernaryExpr(condition, thenBranch, elseBranch,
          source: _currentSource,
          line: condition.line,
          column: condition.column,
          offset: condition.offset,
          length: curTok.offset - condition.offset);
    }
    return condition;
  }

  /// If null: e1 ?? e2, precedence 4, associativity left
  ASTNode _parseIfNullExpr() {
    var left = _parseLogicalOrExpr();
    if (curTok.type == lexicon.ifNull) {
      _leftValueLegality = false;
      while (curTok.type == lexicon.ifNull) {
        final op = advance();
        final right = _parseLogicalOrExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Logical or: ||, precedence 5, associativity left
  ASTNode _parseLogicalOrExpr() {
    var left = _parseLogicalAndExpr();
    if (curTok.type == lexicon.logicalOr) {
      _leftValueLegality = false;
      while (curTok.type == lexicon.logicalOr) {
        final op = advance();
        final right = _parseLogicalAndExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Logical and: &&, precedence 6, associativity left
  ASTNode _parseLogicalAndExpr() {
    var left = _parseEqualityExpr();
    if (curTok.type == lexicon.logicalAnd) {
      _leftValueLegality = false;
      while (curTok.type == lexicon.logicalAnd) {
        final op = advance();
        final right = _parseEqualityExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Logical equal: ==, !=, precedence 7, associativity none
  ASTNode _parseEqualityExpr() {
    var left = _parseRelationalExpr();
    if (lexicon.equalitys.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance();
      final right = _parseRelationalExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: _currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    }
    return left;
  }

  /// Logical compare: <, >, <=, >=, as, is, is!, in, in!, precedence 8, associativity none
  ASTNode _parseRelationalExpr() {
    var left = _parseAdditiveExpr();
    if (lexicon.logicalRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance();
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: _currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (lexicon.setRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance();
      late final String opLexeme;
      if (op.lexeme == lexicon.kIn) {
        opLexeme = expect([lexicon.logicalNot], consume: true)
            ? lexicon.kNotIn
            : lexicon.kIn;
      } else {
        opLexeme = op.lexeme;
      }
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, opLexeme, right,
          source: _currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (lexicon.typeRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance();
      late final String opLexeme;
      if (op.lexeme == lexicon.kIs) {
        opLexeme = expect([lexicon.logicalNot], consume: true)
            ? lexicon.kIsNot
            : lexicon.kIs;
      } else {
        opLexeme = op.lexeme;
      }
      final right = _parseTypeExpr(isLocal: true);
      left = BinaryExpr(left, opLexeme, right,
          source: _currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    }
    return left;
  }

  /// Add: +, -, precedence 13, associativity left
  ASTNode _parseAdditiveExpr() {
    var left = _parseMultiplicativeExpr();
    if (lexicon.additives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (lexicon.additives.contains(curTok.type)) {
        final op = advance();
        final right = _parseMultiplicativeExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Multiply *, /, ~/, %, precedence 14, associativity left
  ASTNode _parseMultiplicativeExpr() {
    var left = _parseUnaryPrefixExpr();
    if (lexicon.multiplicatives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (lexicon.multiplicatives.contains(curTok.type)) {
        final op = advance();
        final right = _parseUnaryPrefixExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Prefix -e, !e，++e, --e, precedence 15, associativity none
  ASTNode _parseUnaryPrefixExpr() {
    if (!(lexicon.unaryPrefixs.contains(curTok.type))) {
      return _parseUnaryPostfixExpr();
    } else {
      final op = advance();
      final value = _parseUnaryPostfixExpr();
      if (lexicon.unaryPrefixsOnLeftValue.contains(op.type)) {
        if (!_leftValueLegality) {
          final err = HTError.invalidLeftValue(
              filename: currrentFileName,
              line: value.line,
              column: value.column,
              offset: value.offset,
              length: value.length);
          errors?.add(err);
        }
      }
      return UnaryPrefixExpr(op.lexeme, value,
          source: _currentSource,
          line: op.line,
          column: op.column,
          offset: op.offset,
          length: curTok.offset - op.offset);
    }
  }

  /// Postfix e., e?., e[], e?[], e(), e?(), e++, e-- precedence 16, associativity right
  ASTNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    while (lexicon.unaryPostfixs.contains(curTok.type)) {
      final op = advance();
      switch (op.type) {
        case lexicon.memberGet:
          var isNullable = false;
          if ((expr is MemberExpr && expr.isNullable) ||
              (expr is SubExpr && expr.isNullable) ||
              (expr is CallExpr && expr.isNullable)) {
            isNullable = true;
          }
          _leftValueLegality = true;
          final name = match(Semantic.identifier);
          final key = IdentifierExpr(name.lexeme,
              isLocal: false,
              source: _currentSource,
              line: name.line,
              column: name.column,
              offset: name.offset,
              length: name.length);
          expr = MemberExpr(expr, key,
              isNullable: isNullable,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case lexicon.nullableMemberGet:
          _leftValueLegality = false;
          final name = match(Semantic.identifier);
          final key = IdentifierExpr(name.lexeme,
              isLocal: false,
              source: _currentSource,
              line: name.line,
              column: name.column,
              offset: name.offset,
              length: name.length);
          expr = MemberExpr(expr, key,
              isNullable: true,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case lexicon.subGetStart:
          var isNullable = false;
          if ((expr is MemberExpr && expr.isNullable) ||
              (expr is SubExpr && expr.isNullable) ||
              (expr is CallExpr && expr.isNullable)) {
            isNullable = true;
          }
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(lexicon.listEnd);
          expr = SubExpr(expr, indexExpr,
              isNullable: isNullable,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case lexicon.nullableSubGet:
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(lexicon.listEnd);
          expr = SubExpr(expr, indexExpr,
              isNullable: true,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case lexicon.nullableFunctionArgumentCall:
          _leftValueLegality = false;
          var positionalArgs = <ASTNode>[];
          var namedArgs = <String, ASTNode>{};
          _handleCallArguments(positionalArgs, namedArgs);
          expr = CallExpr(expr,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              isNullable: true,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case lexicon.functionCallArgumentStart:
          var isNullable = false;
          if ((expr is MemberExpr && expr.isNullable) ||
              (expr is SubExpr && expr.isNullable) ||
              (expr is CallExpr && expr.isNullable)) {
            isNullable = true;
          }
          _leftValueLegality = false;
          var positionalArgs = <ASTNode>[];
          var namedArgs = <String, ASTNode>{};
          _handleCallArguments(positionalArgs, namedArgs);
          expr = CallExpr(expr,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              isNullable: isNullable,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case lexicon.postIncrement:
        case lexicon.postDecrement:
          _leftValueLegality = false;
          expr = UnaryPostfixExpr(expr, op.lexeme,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        default:
          break;
      }
    }
    return expr;
  }

  /// Expression without associativity
  ASTNode _parsePrimaryExpr() {
    switch (curTok.type) {
      case lexicon.kNull:
        final token = advance();
        _leftValueLegality = false;
        return ASTLiteralNull(
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.literalBoolean:
        final token = match(Semantic.literalBoolean) as TokenBooleanLiteral;
        _leftValueLegality = false;
        return ASTLiteralBoolean(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.literalInteger:
        final token = match(Semantic.literalInteger) as TokenIntLiteral;
        _leftValueLegality = false;
        return ASTLiteralInteger(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.literalFloat:
        final token = advance() as TokenFloatLiteral;
        _leftValueLegality = false;
        return ASTLiteralFloat(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.literalString:
        final token = advance() as TokenStringLiteral;
        _leftValueLegality = false;
        return ASTLiteralString(token.literal, token.startMark, token.endMark,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.literalStringInterpolation:
        final token = advance() as TokenStringInterpolation;
        final interpolations = <ASTNode>[];
        for (final token in token.interpolations) {
          final exprParser = HTBundler();
          final nodes = exprParser.parseToken(token,
              source: _currentSource, style: ParseStyle.expression);
          errors?.addAll(exprParser.errors!);

          ASTNode? expr;
          for (final node in nodes) {
            if (node is ASTEmptyLine) continue;
            if (expr == null) {
              expr = node;
            } else {
              final err = HTError.stringInterpolation(
                  filename: currrentFileName,
                  line: node.line,
                  column: node.column,
                  offset: node.offset,
                  length: node.length);
              errors?.add(err);
              break;
            }
          }
          if (expr != null) {
            interpolations.add(expr);
          } else {
            // parser will always contain at least a empty line expr
            interpolations.add(nodes.first);
          }
        }
        var i = 0;
        final text = token.literal.replaceAllMapped(
            RegExp(lexicon.stringInterpolationPattern),
            (Match m) =>
                '${lexicon.functionBlockStart}${i++}${lexicon.functionBlockEnd}');
        _leftValueLegality = false;
        return ASTLiteralStringInterpolation(
            text, token.startMark, token.endMark, interpolations,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case lexicon.kThis:
        final keyword = advance();
        _leftValueLegality = false;
        return IdentifierExpr(keyword.lexeme,
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
      case lexicon.kSuper:
        final keyword = advance();
        _leftValueLegality = false;
        return IdentifierExpr(keyword.lexeme,
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
      case lexicon.kNew:
        final keyword = advance();
        _leftValueLegality = false;
        final idTok = match(Semantic.identifier) as TokenIdentifier;
        final id = IdentifierExpr.fromToken(idTok,
            isMarked: idTok.isMarked, source: _currentSource);
        var positionalArgs = <ASTNode>[];
        var namedArgs = <String, ASTNode>{};
        if (expect([lexicon.functionCallArgumentStart], consume: true)) {
          _handleCallArguments(positionalArgs, namedArgs);
        }
        return CallExpr(id,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            hasNewOperator: true,
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
      case lexicon.kIf:
        _leftValueLegality = false;
        return _parseIf(isExpression: true);
      case lexicon.kWhen:
        _leftValueLegality = false;
        return _parseWhen(isExpression: true);
      case lexicon.groupExprStart:
        // a literal function expression
        final token = seekGroupClosing();
        if (token.type == lexicon.functionBlockStart ||
            token.type == lexicon.functionSingleLineBodyIndicator) {
          _leftValueLegality = false;
          return _parseFunction(
              category: FunctionCategory.literal, hasKeyword: false);
        }
        // a group expression
        else {
          final start = advance();
          final innerExpr = _parseExpr();
          final end = match(lexicon.groupExprEnd);
          _leftValueLegality = false;
          return GroupExpr(innerExpr,
              source: _currentSource,
              line: start.line,
              column: start.column,
              offset: start.offset,
              length: end.offset + end.length - start.offset);
        }
      case lexicon.listStart:
        final start = advance();
        final listExpr = <ASTNode>[];
        while (curTok.type != lexicon.listEnd &&
            curTok.type != Semantic.endOfFile) {
          ASTNode item;
          if (curTok.type == lexicon.spreadSyntax) {
            final spreadTok = advance();
            item = _parseExpr();
            listExpr.add(SpreadExpr(item,
                source: _currentSource,
                line: spreadTok.line,
                column: spreadTok.column,
                offset: spreadTok.offset,
                length: item.end - spreadTok.offset));
          } else {
            item = _parseExpr();
            listExpr.add(item);
          }
          if (curTok.type != lexicon.listEnd) {
            match(lexicon.comma);
          }
          _handleTrailingComment(item);
        }
        final end = match(lexicon.listEnd);
        _leftValueLegality = false;
        return ListExpr(listExpr,
            source: _currentSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: end.end - start.offset);
      case lexicon.functionBlockStart:
        _leftValueLegality = false;
        return _parseStructObj();
      case lexicon.kStruct:
        _leftValueLegality = false;
        return _parseStructObj(hasKeyword: true);
      case lexicon.kFun:
        _leftValueLegality = false;
        return _parseFunction(category: FunctionCategory.literal);
      case Semantic.identifier:
        final id = advance() as TokenIdentifier;
        final isLocal = curTok.type != lexicon.assign;
        // TODO: type arguments
        _leftValueLegality = true;
        return IdentifierExpr.fromToken(id,
            isMarked: id.isMarked, isLocal: isLocal, source: _currentSource);
      default:
        final err = HTError.unexpected(Semantic.expression, curTok.lexeme,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
        final errToken = advance();
        return ASTEmptyLine(
            source: _currentSource,
            line: errToken.line,
            column: errToken.column,
            offset: errToken.offset);
    }
  }

  CommaExpr _handleCommaExpr(String endMark, {bool isLocal = true}) {
    final list = <ASTNode>[];
    while (curTok.type != endMark && curTok.type != Semantic.endOfFile) {
      if (list.isNotEmpty) {
        match(lexicon.comma);
      }
      final item = _parseExpr();
      _handleTrailingComment(item);
      list.add(item);
    }
    return CommaExpr(list,
        isLocal: isLocal,
        source: _currentSource,
        line: list.first.line,
        column: list.first.column,
        offset: list.first.offset,
        length: curTok.offset - list.first.offset);
  }

  InOfExpr _handleInOfExpr() {
    final opTok = advance();
    final collection = _parseExpr();
    return InOfExpr(collection, opTok.lexeme == lexicon.kOf ? true : false,
        line: collection.line,
        column: collection.column,
        offset: collection.offset,
        length: curTok.offset - collection.offset);
  }

  TypeExpr _parseTypeExpr({bool isLocal = false}) {
    // function type
    if (curTok.type == lexicon.groupExprStart) {
      final startTok = advance();
      // TODO: generic parameters
      final parameters = <ParamTypeExpr>[];
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while (curTok.type != lexicon.groupExprEnd &&
          curTok.type != Semantic.endOfFile) {
        final start = curTok;
        if (!isOptional) {
          isOptional = expect([lexicon.listStart], consume: true);
          if (!isOptional && !isNamed) {
            isNamed = expect([lexicon.functionBlockStart], consume: true);
          }
        }
        late final TypeExpr paramType;
        IdentifierExpr? paramSymbol;
        if (!isNamed) {
          isVariadic = expect([lexicon.variadicArgs], consume: true);
        } else {
          final paramId = match(Semantic.identifier);
          paramSymbol =
              IdentifierExpr.fromToken(paramId, source: _currentSource);
          match(lexicon.typeIndicator);
        }
        paramType = _parseTypeExpr();
        final param = ParamTypeExpr(paramType,
            isOptional: isOptional,
            isVariadic: isVariadic,
            id: paramSymbol,
            source: _currentSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: curTok.offset - start.offset);
        if (isOptional && expect([lexicon.listEnd], consume: true)) {
          break;
        } else if (isNamed &&
            expect([lexicon.functionBlockEnd], consume: true)) {
          break;
        } else if (curTok.type != lexicon.groupExprEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(param);
        parameters.add(param);
        if (isVariadic) {
          break;
        }
      }
      match(lexicon.groupExprEnd);
      match(lexicon.functionReturnTypeIndicator);
      final returnType = _parseTypeExpr();
      return FuncTypeExpr(returnType,
          isLocal: isLocal,
          paramTypes: parameters,
          hasOptionalParam: isOptional,
          hasNamedParam: isNamed,
          source: _currentSource,
          line: startTok.line,
          column: startTok.column,
          offset: startTok.offset,
          length: curTok.offset - startTok.offset);
    }
    // structural type (interface of struct)
    else if (curTok.type == lexicon.functionBlockStart) {
      final startTok = advance();
      final fieldTypes = <FieldTypeExpr>[];
      while (curTok.type != lexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        _handlePrecedingComment();
        late Token idTok;
        if (curTok.type == Semantic.literalString) {
          idTok = advance();
        } else {
          idTok = match(Semantic.identifier);
        }
        match(lexicon.typeIndicator);
        final typeExpr = _parseTypeExpr();
        fieldTypes.add(FieldTypeExpr(idTok.literal, typeExpr));
        expect([lexicon.comma], consume: true);
      }
      match(lexicon.functionBlockEnd);
      return StructuralTypeExpr(
        fieldTypes: fieldTypes,
        isLocal: isLocal,
        source: _currentSource,
        line: startTok.line,
        column: startTok.column,
        length: curTok.offset - startTok.offset,
      );
    }
    // nominal type (class)
    else {
      final idTok = match(Semantic.identifier);
      final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
      final typeArgs = <TypeExpr>[];
      if (expect([lexicon.typeParameterStart], consume: true)) {
        if (curTok.type == lexicon.typeParameterEnd) {
          final err = HTError.emptyTypeArgs(
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.end - idTok.offset);
          errors?.add(err);
        }
        while ((curTok.type != lexicon.typeParameterEnd) &&
            (curTok.type != Semantic.endOfFile)) {
          final typeArg = _parseTypeExpr();
          expect([lexicon.comma], consume: true);
          _handleTrailingComment(typeArg);
          typeArgs.add(typeArg);
        }
        match(lexicon.typeParameterEnd);
      }
      final isNullable = expect([lexicon.nullableTypePostfix], consume: true);
      return TypeExpr(
        id: id,
        arguments: typeArgs,
        isNullable: isNullable,
        isLocal: isLocal,
        source: _currentSource,
        line: idTok.line,
        column: idTok.column,
        offset: idTok.offset,
        length: curTok.offset - idTok.offset,
      );
    }
  }

  BlockStmt _parseBlockStmt(
      {String? id,
      ParseStyle sourceType = ParseStyle.functionDefinition,
      bool hasOwnNamespace = true}) {
    final startTok = match(lexicon.functionBlockStart);
    final statements = <ASTNode>[];
    while (curTok.type != lexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      final stmt = _parseStmt(sourceType: sourceType);
      if (stmt != null) {
        statements.add(stmt);
      }
    }
    final endTok = match(lexicon.functionBlockEnd);
    if (statements.isEmpty) {
      final empty = ASTEmptyLine(
          source: _currentSource,
          line: endTok.line,
          column: endTok.column,
          offset: endTok.offset,
          length: endTok.offset - startTok.end);
      empty.precedingComments = _currentPrecedingComments;
      _currentPrecedingComments = [];
      statements.add(empty);
    }

    return BlockStmt(statements,
        id: id,
        hasOwnNamespace: hasOwnNamespace,
        source: _currentSource,
        line: startTok.line,
        column: startTok.column,
        offset: startTok.offset,
        length: curTok.offset - startTok.offset);
  }

  void _handleCallArguments(
      List<ASTNode> positionalArgs, Map<String, ASTNode> namedArgs) {
    var isNamed = false;
    while ((curTok.type != lexicon.groupExprEnd) &&
        (curTok.type != Semantic.endOfFile)) {
      if ((!isNamed &&
              expect([Semantic.identifier, lexicon.namedArgumentValueIndicator],
                  consume: false)) ||
          isNamed) {
        isNamed = true;
        final name = match(Semantic.identifier).lexeme;
        match(lexicon.namedArgumentValueIndicator);
        final namedArg = _parseExpr();
        if (curTok.type != lexicon.groupExprEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(namedArg);
        namedArgs[name] = namedArg;
      } else {
        late ASTNode positionalArg;
        if (curTok.type == lexicon.spreadSyntax) {
          final spreadTok = advance();
          final spread = _parseExpr();
          positionalArg = SpreadExpr(spread,
              source: _currentSource,
              line: spreadTok.line,
              column: spreadTok.column,
              offset: spreadTok.offset,
              length: spread.end - spreadTok.offset);
        } else {
          positionalArg = _parseExpr();
        }
        if (curTok.type != lexicon.groupExprEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(positionalArg);
        positionalArgs.add(positionalArg);
      }
    }
    match(lexicon.functionCallArgumentEnd);
  }

  ASTNode _parseExprStmt() {
    if (curTok.type == lexicon.endOfStatementMark) {
      final empty = advance();
      final stmt = ASTEmptyLine(
          hasEndOfStmtMark: true,
          source: _currentSource,
          line: empty.line,
          column: empty.column,
          offset: empty.offset,
          length: curTok.offset - empty.offset);
      return stmt;
    } else {
      final expr = _parseExpr();
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      final stmt = ExprStmt(expr,
          hasEndOfStmtMark: hasEndOfStmtMark,
          source: _currentSource,
          line: expr.line,
          column: expr.column,
          offset: expr.offset,
          length: curTok.offset - expr.offset);
      return stmt;
    }
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance();
    ASTNode? expr;
    if (curTok.type != lexicon.functionBlockEnd &&
        curTok.type != lexicon.endOfStatementMark &&
        curTok.type != Semantic.endOfFile) {
      expr = _parseExpr();
    }
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
    return ReturnStmt(keyword,
        returnValue: expr,
        source: _currentSource,
        hasEndOfStmtMark: hasEndOfStmtMark,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  ASTNode _parseExprOrStmtOrBlock({bool isExpression = false}) {
    if (curTok.type == lexicon.functionBlockStart) {
      return _parseBlockStmt(id: Semantic.elseBranch);
    } else {
      if (isExpression) {
        return _parseExpr();
      } else {
        final startTok = curTok;
        var node = _parseStmt();
        if (node == null) {
          final err = HTError.unexpected(Semantic.expression, curTok.lexeme,
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors?.add(err);
          node = ASTEmptyLine(
              source: _currentSource,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.offset - startTok.offset);
          node.precedingComments.addAll(_currentPrecedingComments);
          _currentPrecedingComments.clear();
        }
        return node;
      }
    }
  }

  IfStmt _parseIf({bool isExpression = false}) {
    final keyword = match(lexicon.kIf);
    match(lexicon.groupExprStart);
    final condition = _parseExpr();
    match(lexicon.groupExprEnd);
    var thenBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
    _handlePrecedingComment();
    ASTNode? elseBranch;
    if (isExpression) {
      match(lexicon.kElse);
      elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
    } else {
      if (expect([lexicon.kElse], consume: true)) {
        elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
      }
    }
    return IfStmt(condition, thenBranch,
        isExpression: isExpression,
        elseBranch: elseBranch,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  WhileStmt _parseWhileStmt() {
    final keyword = match(lexicon.kWhile);
    match(lexicon.groupExprStart);
    final condition = _parseExpr();
    match(lexicon.groupExprEnd);
    final loop = _parseBlockStmt(id: Semantic.whileLoop);
    return WhileStmt(condition, loop,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DoStmt _parseDoStmt() {
    final keyword = advance();
    final loop = _parseBlockStmt(id: Semantic.doLoop);
    ASTNode? condition;
    if (expect([lexicon.kWhile], consume: true)) {
      match(lexicon.groupExprStart);
      condition = _parseExpr();
      match(lexicon.groupExprEnd);
    }
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
    return DoStmt(loop, condition,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  ASTNode _parseForStmt() {
    final keyword = advance();
    final hasBracket = expect([lexicon.groupExprStart], consume: true);
    final forStmtType = peek(2).lexeme;
    VarDecl? decl;
    ASTNode? condition;
    ASTNode? increment;
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (forStmtType == lexicon.kIn || forStmtType == lexicon.kOf) {
      if (!lexicon.forDeclarationKeywords.contains(curTok.type)) {
        final err = HTError.unexpected(
            Semantic.variableDeclaration, curTok.type,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      decl = _parseVarDecl(
          // typeInferrence: curTok.type != lexicon.VAR,
          isMutable: curTok.type != lexicon.kFinal);
      advance();
      final collection = _parseExpr();
      if (hasBracket) {
        match(lexicon.groupExprEnd);
      }
      final loop = _parseBlockStmt(id: Semantic.forLoop);
      return ForRangeStmt(decl, collection, loop,
          hasBracket: hasBracket,
          iterateValue: forStmtType == lexicon.kOf,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      if (!expect([lexicon.endOfStatementMark], consume: false)) {
        decl = _parseVarDecl(
            // typeInferrence: curTok.type != lexicon.VAR,
            isMutable: curTok.type != lexicon.kFinal,
            hasEndOfStatement: true);
      } else {
        match(lexicon.endOfStatementMark);
      }
      if (!expect([lexicon.endOfStatementMark], consume: false)) {
        condition = _parseExpr();
      }
      match(lexicon.endOfStatementMark);
      if (!expect([lexicon.groupExprEnd], consume: false)) {
        increment = _parseExpr();
      }
      if (hasBracket) {
        match(lexicon.groupExprEnd);
      }
      final loop = _parseBlockStmt(id: Semantic.forLoop);
      return ForStmt(decl, condition, increment, loop,
          hasBracket: hasBracket,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    }
  }

  WhenStmt _parseWhen({bool isExpression = false}) {
    final keyword = advance();
    ASTNode? condition;
    if (curTok.type != lexicon.functionBlockStart) {
      match(lexicon.groupExprStart);
      condition = _parseExpr();
      match(lexicon.groupExprEnd);
    }
    final options = <ASTNode, ASTNode>{};
    ASTNode? elseBranch;
    match(lexicon.functionBlockStart);
    while (curTok.type != lexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      _handlePrecedingComment();
      if (curTok.lexeme == lexicon.kElse) {
        advance();
        match(lexicon.whenBranchIndicator);
        elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
      } else {
        ASTNode caseExpr;
        if (condition != null) {
          if (peek(1).type == lexicon.comma) {
            caseExpr =
                _handleCommaExpr(lexicon.whenBranchIndicator, isLocal: false);
          } else if (curTok.type == lexicon.kIn) {
            caseExpr = _handleInOfExpr();
          } else {
            caseExpr = _parseExpr();
          }
        } else {
          caseExpr = _parseExpr();
        }
        match(lexicon.whenBranchIndicator);
        var caseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
        options[caseExpr] = caseBranch;
      }
    }
    match(lexicon.functionBlockEnd);
    return WhenStmt(options, elseBranch, condition,
        isExpression: isExpression,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  List<GenericTypeParameterExpr> _getGenericParams() {
    final genericParams = <GenericTypeParameterExpr>[];
    if (expect([lexicon.typeParameterStart], consume: true)) {
      while ((curTok.type != lexicon.typeParameterEnd) &&
          (curTok.type != Semantic.endOfFile)) {
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
        final param = GenericTypeParameterExpr(id,
            source: _currentSource,
            line: idTok.line,
            column: idTok.column,
            offset: idTok.offset,
            length: curTok.offset - idTok.offset);
        if (curTok.type != lexicon.typeParameterEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(param);
        genericParams.add(param);
      }
      match(lexicon.typeParameterEnd);
    }
    return genericParams;
  }

  ImportExportDecl _parseImportDecl() {
    // TODO: duplicate import and self import error.
    final keyword = advance(); // not a keyword so don't use match
    final showList = <IdentifierExpr>[];
    if (curTok.type == lexicon.functionBlockStart) {
      advance();
      if (curTok.type == lexicon.functionBlockEnd) {
        final err = HTError.emptyImportList(
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.end - keyword.offset);
        errors?.add(err);
      }
      while (curTok.type != lexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        _handlePrecedingComment();
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
        if (curTok.type != lexicon.functionBlockEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(id);
        showList.add(id);
      }
      match(lexicon.functionBlockEnd);
      // check lexeme here because expect() can only deal with token type
      final fromKeyword = advance().lexeme;
      if (fromKeyword != lexicon.kFrom) {
        final err = HTError.unexpected(lexicon.kFrom, curTok.lexeme,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
    }
    IdentifierExpr? alias;
    late bool hasEndOfStmtMark;
    void _handleAlias() {
      final aliasId = match(Semantic.identifier);
      alias = IdentifierExpr.fromToken(aliasId, source: _currentSource);
      hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    }

    final fromPathTok = match(Semantic.literalString);
    String fromPathRaw = fromPathTok.literal;
    String fromPath;
    bool isPreloadedModule = false;
    if (fromPathRaw.startsWith(HTResourceContext.hetuPreloadedModulesPrefix)) {
      isPreloadedModule = true;
      fromPath = fromPathRaw
          .substring(HTResourceContext.hetuPreloadedModulesPrefix.length);
      hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    } else {
      fromPath = fromPathRaw;
      final ext = path.extension(fromPathTok.lexeme);
      if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
        if (showList.isNotEmpty) {
          final err = HTError.importListOnNonHetuSource(
              filename: currrentFileName,
              line: fromPathTok.line,
              column: fromPathTok.column,
              offset: fromPathTok.offset,
              length: fromPathTok.length);
          errors?.add(err);
        }
        match(lexicon.kAs);
        _handleAlias();
      } else {
        hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
        if (!hasEndOfStmtMark && expect([lexicon.kAs], consume: true)) {
          _handleAlias();
        }
      }
    }
    final stmt = ImportExportDecl(
        fromPath: fromPath,
        showList: showList,
        alias: alias,
        hasEndOfStmtMark: hasEndOfStmtMark,
        isPreloadedModule: isPreloadedModule,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    _currentModuleImports.add(stmt);
    expect([lexicon.endOfStatementMark], consume: true);
    return stmt;
  }

  ImportExportDecl _parseExportStmt() {
    final keyword = advance(); // not a keyword so don't use match
    late final ImportExportDecl stmt;
    // export some of the symbols from this or other source
    if (curTok.type == lexicon.functionBlockStart) {
      advance();
      final showList = <IdentifierExpr>[];
      while (curTok.type != lexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        _handlePrecedingComment();
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
        if (curTok.type != lexicon.functionBlockEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(id);
        showList.add(id);
      }
      match(lexicon.functionBlockEnd);
      String? fromPath;
      var hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      if (!hasEndOfStmtMark && curTok.lexeme == lexicon.kFrom) {
        advance();
        final fromPathTok = match(Semantic.literalString);
        final ext = path.extension(fromPathTok.literal);
        if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
          final err = HTError.importListOnNonHetuSource(
              filename: currrentFileName,
              line: fromPathTok.line,
              column: fromPathTok.column,
              offset: fromPathTok.offset,
              length: fromPathTok.length);
          errors?.add(err);
        }
        hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
      }
      stmt = ImportExportDecl(
          fromPath: fromPath,
          showList: showList,
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExport: true,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      if (fromPath != null) {
        _currentModuleImports.add(stmt);
      }
    }
    // export all of the symbols from other source
    else {
      final key = match(Semantic.literalString);
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      stmt = ImportExportDecl(
          fromPath: key.literal,
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExport: true,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      _currentModuleImports.add(stmt);
    }
    return stmt;
  }

  ASTNode _parseDeleteStmt() {
    var keyword = advance();
    final nextTok = peek(1);
    if (curTok.type == Semantic.identifier &&
        nextTok.type != lexicon.memberGet &&
        nextTok.type != lexicon.subGetStart) {
      final id = advance().lexeme;
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      return DeleteStmt(id,
          source: _currentSource,
          hasEndOfStmtMark: hasEndOfStmtMark,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      final expr = _parseExpr();
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      if (expr is MemberExpr) {
        return DeleteMemberStmt(expr.object, expr.key.id,
            hasEndOfStmtMark: hasEndOfStmtMark,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
      } else if (expr is SubExpr) {
        return DeleteSubStmt(expr.object, expr.key,
            hasEndOfStmtMark: hasEndOfStmtMark,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
      } else {
        final err = HTError.delete(
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
        final empty = ASTEmptyLine(
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
        return empty;
      }
    }
  }

  NamespaceDecl _parseNamespaceDecl({bool isTopLevel = false}) {
    final keyword = match(lexicon.kNamespace);
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
    final definition = _parseBlockStmt(
        id: id.id, sourceType: ParseStyle.module, hasOwnNamespace: false);
    return NamespaceDecl(
      id,
      definition,
      classId: _currentClass?.id,
      isTopLevel: isTopLevel,
      source: _currentSource,
      line: keyword.line,
      column: keyword.column,
      offset: keyword.offset,
      length: curTok.end - keyword.offset,
    );
  }

  TypeAliasDecl _parseTypeAliasDecl(
      {String? classId, bool isTopLevel = false}) {
    final keyword = advance();
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
    final genericParameters = _getGenericParams();
    match(lexicon.assign);
    final value = _parseTypeExpr();
    return TypeAliasDecl(id, value,
        classId: classId,
        genericTypeParameters: genericParameters,
        isTopLevel: isTopLevel,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  VarDecl _parseVarDecl(
      {String? classId,
      bool isField = false,
      // bool typeInferrence = false,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isMutable = false,
      bool isTopLevel = false,
      bool lateFinalize = false,
      bool lateInitialize = false,
      ASTNode? additionalInitializer,
      bool hasEndOfStatement = false}) {
    final keyword = advance();
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
    String? internalName;
    if (classId != null && isExternal) {
      // if (!(_currentClass!.isExternal) && !isStatic) {
      //   final err = HTError.externalMember(
      //       filename: currrentFileName,
      //       line: keyword.line,
      //       column: keyword.column,
      //       offset: curTok.offset,
      //       length: curTok.length);
      //   errors?.add(err);
      // }
      internalName = '$classId.${idTok.lexeme}';
    }
    TypeExpr? declType;
    if (expect([lexicon.typeIndicator], consume: true)) {
      declType = _parseTypeExpr();
    }
    ASTNode? initializer;
    if (!lateFinalize) {
      if (isConst) {
        match(lexicon.assign);
        initializer = _parseExpr();
      } else {
        if (expect([lexicon.assign], consume: true)) {
          initializer = _parseExpr();
        } else {
          initializer = additionalInitializer;
        }
      }
    }
    bool hasEndOfStmtMark = hasEndOfStatement;
    if (hasEndOfStatement) {
      match(lexicon.endOfStatementMark);
    } else {
      hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    }
    return VarDecl(id,
        internalName: internalName,
        classId: classId,
        declType: declType,
        initializer: initializer,
        hasEndOfStmtMark: hasEndOfStmtMark,
        isField: isField,
        isExternal: isExternal,
        isStatic: isConst && classId != null ? true : isStatic,
        isConst: isConst,
        isMutable: !isConst && isMutable,
        isTopLevel: isTopLevel,
        lateFinalize: lateFinalize,
        lateInitialize: lateInitialize,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DestructuringDecl _parseDestructuringDecl({bool isMutable = false}) {
    final keyword = advance(2);
    final ids = <IdentifierExpr, TypeExpr?>{};
    bool isVector = false;
    String endMark;
    if (peek(-1).type == lexicon.listStart) {
      endMark = lexicon.listEnd;
      isVector = true;
    } else {
      endMark = lexicon.functionBlockEnd;
    }
    while (curTok.type != endMark && curTok.type != Semantic.endOfFile) {
      _handlePrecedingComment();
      final idTok = match(Semantic.identifier);
      final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
      TypeExpr? declType;
      if (expect([lexicon.typeIndicator], consume: true)) {
        declType = _parseTypeExpr();
      }
      if (curTok.type != endMark) {
        match(lexicon.comma);
      }
      if (declType == null) {
        _handleTrailingComment(id);
      } else {
        _handleTrailingComment(declType);
      }
      ids[id] = declType;
    }
    match(endMark);
    match(lexicon.assign);
    final initializer = _parseExpr();
    bool hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    return DestructuringDecl(
        ids: ids,
        isVector: isVector,
        initializer: initializer,
        hasEndOfStmtMark: hasEndOfStmtMark,
        isMutable: isMutable,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  FuncDecl _parseFunction(
      {FunctionCategory category = FunctionCategory.normal,
      String? classId,
      bool hasKeyword = true,
      bool isAsync = false,
      bool isField = false,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isTopLevel = false}) {
    final savedCurFuncType = _currentFunctionCategory;
    _currentFunctionCategory = category;
    late Token startTok;
    String? externalTypedef;
    if (category != FunctionCategory.literal || hasKeyword) {
      // there are multiple keyword for function, so don't use match here.
      startTok = advance();
      if (!isExternal &&
          (isStatic ||
              category == FunctionCategory.normal ||
              category == FunctionCategory.literal)) {
        if (expect([lexicon.listStart], consume: true)) {
          externalTypedef = match(Semantic.identifier).lexeme;
          match(lexicon.listEnd);
        }
      }
    }
    Token? id;
    late String internalName;
    // to distinguish getter and setter, and to give default constructor a name
    switch (category) {
      case FunctionCategory.factoryConstructor:
      case FunctionCategory.constructor:
        _hasUserDefinedConstructor = true;
        if (curTok.type == Semantic.identifier) {
          id = advance();
        }
        internalName = (id == null)
            ? InternalIdentifier.defaultConstructor
            : '${InternalIdentifier.namedConstructorPrefix}$id';
        break;
      case FunctionCategory.literal:
        if (curTok.type == Semantic.identifier) {
          id = advance();
        }
        internalName = (id == null)
            ? '${InternalIdentifier.anonymousFunction}${anonymousFunctionIndex++}'
            : id.lexeme;
        break;
      case FunctionCategory.getter:
        id = match(Semantic.identifier);
        internalName = '${InternalIdentifier.getter}$id';
        break;
      case FunctionCategory.setter:
        id = match(Semantic.identifier);
        internalName = '${InternalIdentifier.setter}$id';
        break;
      default:
        id = match(Semantic.identifier);
        internalName = id.lexeme;
    }
    final genericParameters = _getGenericParams();
    var isFuncVariadic = false;
    var minArity = 0;
    var maxArity = 0;
    var paramDecls = <ParamDecl>[];
    var hasParamDecls = false;
    if (category != FunctionCategory.getter &&
        expect([lexicon.groupExprStart], consume: true)) {
      final startTok = curTok;
      hasParamDecls = true;
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while ((curTok.type != lexicon.groupExprEnd) &&
          (curTok.type != lexicon.listEnd) &&
          (curTok.type != lexicon.functionBlockEnd) &&
          (curTok.type != Semantic.endOfFile)) {
        _handlePrecedingComment();
        // 可选参数, 根据是否有方括号判断, 一旦开始了可选参数, 则不再增加参数数量arity要求
        if (!isOptional) {
          isOptional = expect([lexicon.listStart], consume: true);
          if (!isOptional && !isNamed) {
            //检查命名参数, 根据是否有花括号判断
            isNamed = expect([lexicon.functionBlockStart], consume: true);
          }
        }
        if (!isNamed) {
          isVariadic = expect([lexicon.variadicArgs], consume: true);
        }
        if (!isNamed && !isVariadic) {
          if (!isOptional) {
            ++minArity;
            ++maxArity;
          } else {
            ++maxArity;
          }
        }
        final paramId = match(Semantic.identifier);
        final paramSymbol =
            IdentifierExpr.fromToken(paramId, source: _currentSource);
        TypeExpr? paramDeclType;
        if (expect([lexicon.typeIndicator], consume: true)) {
          paramDeclType = _parseTypeExpr();
        }
        ASTNode? initializer;
        if (expect([lexicon.assign], consume: true)) {
          if (isOptional || isNamed) {
            initializer = _parseExpr();
          } else {
            final lastTok = peek(-1);
            final err = HTError.argInit(
                filename: currrentFileName,
                line: lastTok.line,
                column: lastTok.column,
                offset: lastTok.offset,
                length: lastTok.length);
            errors?.add(err);
          }
        }
        final param = ParamDecl(paramSymbol,
            declType: paramDeclType,
            initializer: initializer,
            isVariadic: isVariadic,
            isOptional: isOptional,
            isNamed: isNamed,
            source: _currentSource,
            line: paramId.line,
            column: paramId.column,
            offset: paramId.offset,
            length: curTok.offset - paramId.offset);
        if (curTok.type != lexicon.listEnd &&
            curTok.type != lexicon.functionBlockEnd &&
            curTok.type != lexicon.groupExprEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(param);
        paramDecls.add(param);
        if (isVariadic) {
          isFuncVariadic = true;
          break;
        }
      }
      if (isOptional) {
        match(lexicon.listEnd);
      } else if (isNamed) {
        match(lexicon.functionBlockEnd);
      }

      final endTok = match(lexicon.groupExprEnd);

      // setter can only have one parameter
      if ((category == FunctionCategory.setter) && (minArity != 1)) {
        final err = HTError.setterArity(
            filename: currrentFileName,
            line: startTok.line,
            column: startTok.column,
            offset: startTok.offset,
            length: endTok.offset + endTok.length - startTok.offset);
        errors?.add(err);
      }
    }

    TypeExpr? returnType;
    RedirectingConstructorCallExpr? referCtor;
    // the return value type declaration
    if (expect([lexicon.functionReturnTypeIndicator], consume: true)) {
      if (category == FunctionCategory.constructor ||
          category == FunctionCategory.setter) {
        final err = HTError.unexpected(
            Semantic.functionDefinition, Semantic.returnType,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      returnType = _parseTypeExpr();
    }
    // referring to another constructor
    else if (expect([lexicon.constructorInitializationListIndicator],
        consume: true)) {
      if (category != FunctionCategory.constructor) {
        final lastTok = peek(-1);
        final err = HTError.unexpected(lexicon.functionBlockStart,
            lexicon.constructorInitializationListIndicator,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors?.add(err);
      }
      if (isExternal) {
        final lastTok = peek(-1);
        final err = HTError.externalCtorWithReferCtor(
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors?.add(err);
      }
      final ctorCallee = advance();
      if (!lexicon.redirectingConstructorCallKeywords
          .contains(ctorCallee.lexeme)) {
        final err = HTError.unexpected(Semantic.ctorCallExpr, curTok.lexeme,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: ctorCallee.offset,
            length: ctorCallee.length);
        errors?.add(err);
      }
      Token? ctorKey;
      if (expect([lexicon.memberGet], consume: true)) {
        ctorKey = match(Semantic.identifier);
        match(lexicon.groupExprStart);
      } else {
        match(lexicon.groupExprStart);
      }
      var positionalArgs = <ASTNode>[];
      var namedArgs = <String, ASTNode>{};
      _handleCallArguments(positionalArgs, namedArgs);
      referCtor = RedirectingConstructorCallExpr(
          IdentifierExpr.fromToken(ctorCallee, source: _currentSource),
          positionalArgs,
          namedArgs,
          key: ctorKey != null
              ? IdentifierExpr.fromToken(ctorKey, source: _currentSource)
              : null,
          source: _currentSource,
          line: ctorCallee.line,
          column: ctorCallee.column,
          offset: ctorCallee.offset,
          length: curTok.offset - ctorCallee.offset);
    }
    bool isExpressionBody = false;
    bool hasEndOfStmtMark = false;
    ASTNode? definition;
    if (curTok.type == lexicon.functionBlockStart) {
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseBlockStmt(id: Semantic.functionCall);
    } else if (expect([lexicon.functionSingleLineBodyIndicator],
        consume: true)) {
      isExpressionBody = true;
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseExpr();
      hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    } else if (expect([lexicon.assign], consume: true)) {
      final err = HTError.unsupported(Semantic.redirectingFunctionDefinition,
          filename: currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors?.add(err);
    } else {
      if (category != FunctionCategory.constructor &&
          category != FunctionCategory.literal &&
          !isExternal &&
          !(_currentClass?.isAbstract ?? false)) {
        final err = HTError.missingFuncBody(internalName,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      if (category != FunctionCategory.literal) {
        expect([lexicon.endOfStatementMark], consume: true);
      }
    }
    _currentFunctionCategory = savedCurFuncType;
    return FuncDecl(internalName, paramDecls,
        id: id != null
            ? IdentifierExpr.fromToken(id, source: _currentSource)
            : null,
        classId: classId,
        genericTypeParameters: genericParameters,
        externalTypeId: externalTypedef,
        returnType: returnType,
        redirectingCtorCallExpr: referCtor,
        hasParamDecls: hasParamDecls,
        minArity: minArity,
        maxArity: maxArity,
        isExpressionBody: isExpressionBody,
        hasEndOfStmtMark: hasEndOfStmtMark,
        definition: definition,
        isField: isField,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        isVariadic: isFuncVariadic,
        isTopLevel: isTopLevel,
        category: category,
        source: _currentSource,
        line: startTok.line,
        column: startTok.column,
        offset: startTok.offset,
        length: curTok.offset - startTok.offset);
  }

  ClassDecl _parseClassDecl(
      {String? classId,
      bool isExternal = false,
      bool isAbstract = false,
      bool isTopLevel = false,
      bool lateResolve = true}) {
    final keyword = match(lexicon.kClass);
    if (_currentClass != null && _currentClass!.isNested) {
      final err = HTError.nestedClass(
          filename: currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: keyword.offset,
          length: keyword.length);
      errors?.add(err);
    }
    final id = match(Semantic.identifier);
    final genericParameters = _getGenericParams();
    TypeExpr? superClassType;
    if (curTok.lexeme == lexicon.kExtends) {
      advance();
      if (curTok.lexeme == id.lexeme) {
        final err = HTError.extendsSelf(
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      superClassType = _parseTypeExpr();
    }
    final savedClass = _currentClass;
    _currentClass = HTClassDeclaration(
        id: id.lexeme,
        classId: classId,
        isExternal: isExternal,
        isAbstract: isAbstract);
    final savedHasUsrDefCtor = _hasUserDefinedConstructor;
    _hasUserDefinedConstructor = false;
    final definition = _parseBlockStmt(
        sourceType: ParseStyle.classDefinition,
        hasOwnNamespace: false,
        id: Semantic.classDefinition);
    final decl = ClassDecl(
        IdentifierExpr.fromToken(id, source: _currentSource), definition,
        genericTypeParameters: genericParameters,
        superType: superClassType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isTopLevel: isTopLevel,
        hasUserDefinedConstructor: _hasUserDefinedConstructor,
        lateResolve: lateResolve,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    _hasUserDefinedConstructor = savedHasUsrDefCtor;
    _currentClass = savedClass;
    return decl;
  }

  EnumDecl _parseEnumDecl({bool isExternal = false, bool isTopLevel = false}) {
    final keyword = match(lexicon.kEnum);
    final id = match(Semantic.identifier);
    var enumerations = <IdentifierExpr>[];
    if (expect([lexicon.functionBlockStart], consume: true)) {
      _handlePrecedingComment();
      while (curTok.type != lexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        final enumIdTok = match(Semantic.identifier);
        final enumId =
            IdentifierExpr.fromToken(enumIdTok, source: _currentSource);
        if (curTok.type != lexicon.functionBlockEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(enumId);
        enumerations.add(enumId);
      }
      match(lexicon.functionBlockEnd);
    } else {
      expect([lexicon.endOfStatementMark], consume: true);
    }
    return EnumDecl(
        IdentifierExpr.fromToken(id, source: _currentSource), enumerations,
        isExternal: isExternal,
        isTopLevel: isTopLevel,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  StructDecl _parseStructDecl(
      {bool isTopLevel = false, bool lateInitialize = true}) {
    final keyword = match(lexicon.kStruct);
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
    IdentifierExpr? prototypeId;
    if (expect([lexicon.kExtends], consume: true)) {
      final prototypeIdTok = match(Semantic.identifier);
      if (prototypeIdTok.lexeme == id.id) {
        final err = HTError.extendsSelf(
            filename: currrentFileName,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
        errors?.add(err);
      }
      prototypeId =
          IdentifierExpr.fromToken(prototypeIdTok, source: _currentSource);
    }
    final savedStructId = _currentStructId;
    _currentStructId = id.id;
    final definition = <ASTNode>[];
    final startTok = match(lexicon.functionBlockStart);
    while (curTok.type != lexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      final stmt = _parseStmt(sourceType: ParseStyle.structDefinition);
      if (stmt != null) {
        definition.add(stmt);
      }
    }
    final endTok = match(lexicon.functionBlockEnd);
    if (definition.isEmpty) {
      final empty = ASTEmptyLine(
          source: _currentSource,
          line: endTok.line,
          column: endTok.column,
          offset: endTok.offset,
          length: endTok.offset - startTok.end);
      empty.precedingComments.addAll(_currentPrecedingComments);
      _currentPrecedingComments.clear();
      definition.add(empty);
    }
    _currentStructId = savedStructId;
    return StructDecl(id, definition,
        prototypeId: prototypeId,
        isTopLevel: isTopLevel,
        lateInitialize: lateInitialize,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  StructObjExpr _parseStructObj({bool hasKeyword = false}) {
    IdentifierExpr? prototypeId;
    if (hasKeyword) {
      match(lexicon.kStruct);
      if (hasKeyword && expect([lexicon.kExtends], consume: true)) {
        final idTok = match(Semantic.identifier);
        prototypeId = IdentifierExpr.fromToken(idTok, source: _currentSource);
      }
    }
    prototypeId ??= IdentifierExpr(lexicon.globalPrototypeId);
    final structBlockStartTok = match(lexicon.functionBlockStart);
    final fields = <StructObjField>[];
    while (curTok.type != lexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      if (curTok.type == Semantic.identifier ||
          curTok.type == Semantic.literalString) {
        final keyTok = advance();
        late final StructObjField field;
        if (curTok.type == lexicon.comma ||
            curTok.type == lexicon.functionBlockEnd) {
          final id = IdentifierExpr.fromToken(keyTok, source: _currentSource);
          field = StructObjField(
              key: IdentifierExpr.fromToken(
                keyTok,
                isLocal: false,
                source: _currentSource,
              ),
              fieldValue: id);
        } else {
          match(lexicon.structValueIndicator);
          final value = _parseExpr();
          field = StructObjField(
              key: IdentifierExpr.fromToken(
                keyTok,
                isLocal: false,
                source: _currentSource,
              ),
              fieldValue: value);
        }
        if (curTok.type != lexicon.functionBlockEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(field);
        fields.add(field);
      } else if (curTok.type == lexicon.spreadSyntax) {
        advance();
        final value = _parseExpr();
        final field = StructObjField(fieldValue: value, isSpread: true);
        if (curTok.type != lexicon.functionBlockEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(field);
        fields.add(field);
      } else if (curTok is TokenComment) {
        _handlePrecedingComment();
      } else {
        final errTok = advance();
        final err = HTError.structMemberId(
            filename: currrentFileName,
            line: errTok.line,
            column: errTok.column,
            offset: errTok.offset,
            length: errTok.length);
        errors?.add(err);
      }
    }
    if (fields.isEmpty) {
      final empty = StructObjField(
          source: _currentSource,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.offset - structBlockStartTok.offset);
      empty.precedingComments.addAll(_currentPrecedingComments);
      _currentPrecedingComments.clear();
      fields.add(empty);
    }
    match(lexicon.functionBlockEnd);
    return StructObjExpr(fields,
        prototypeId: prototypeId,
        source: _currentSource,
        line: structBlockStartTok.line,
        column: structBlockStartTok.column,
        offset: structBlockStartTok.offset,
        length: curTok.offset - structBlockStartTok.offset);
  }
}
