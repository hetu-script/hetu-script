import 'package:path/path.dart' as path;

import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../resource/overlay/overlay_context.dart';
import '../grammar/lexicon.dart';
import '../lexer/token.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../declaration/class/class_declaration.dart';
import '../error/error.dart';
import '../ast/ast.dart';
import 'parse_result.dart';
import 'parse_result_compilation.dart';
// import '../error/error_handler.dart';
import 'abstract_parser.dart';
import '../lexer/lexer.dart';

/// Determines how to parse a piece of code
enum ParseStyle {
  /// Module source can only have declarations (variables, functions, classes, enums),
  /// import & export statement.
  module,

  /// A script can have all statements and expressions, kind of like a funciton body.
  script,

  /// An expression.
  expression,

  /// Like module, but no import & export allowed.
  namespace,

  /// Class can only have declarations (variables, functions).
  classDefinition,

  /// Struct can not have external members
  structDefinition,

  /// Function & block can have declarations (variables, functions),
  /// expression & control statements.
  functionDefinition,
}

/// Walk through a token list and generates a abstract syntax tree.
class HTParser extends HTAbstractParser {
  static var anonymousFunctionIndex = 0;

  // All import decl in this list must have non-null [fromPath]
  final _currentModuleImports = <ImportExportDecl>[];

  String? _currrentFileName;
  @override
  String? get currrentFileName => _currrentFileName;

  late String _currentModuleName;
  @override
  String? get currentModuleName => _currentModuleName;

  final _currentPrecedingComments = <Comment>[];

  HTClassDeclaration? _currentClass;
  FunctionCategory? _currentFunctionCategory;
  String? _currentStructId;

  var _leftValueLegality = false;
  final List<Map<String, String>> _markedSymbolsList = [];

  bool _hasUserDefinedConstructor = false;

  HTSource? _currentSource;

  final _cachedParseResults = <String, HTSourceParseResult>{};

  final Set<String> _cachedRecursiveParsingTargets = {};

  @override
  final HTResourceContext<HTSource> sourceContext;

  HTParser({HTResourceContext<HTSource>? context})
      : sourceContext = context ?? HTOverlayContext();

  /// Will use [style] when possible, then [source.sourceType]
  List<AstNode> parseToken(List<Token> tokens,
      {HTSource? source, ParseStyle? style, ParserConfig? config}) {
    // create new list of errors here, old error list is still usable
    errors = <HTError>[];
    final nodes = <AstNode>[];
    _currentSource = source;
    _currrentFileName = source?.fullName;
    setTokens(tokens);
    while (curTok.type != Semantic.endOfFile) {
      late ParseStyle parseStyle;
      if (style != null) {
        parseStyle = style;
      } else {
        if (_currentSource != null) {
          final sourceType = _currentSource!.type;
          if (sourceType == ResourceType.hetuModule) {
            parseStyle = ParseStyle.module;
          } else if (sourceType == ResourceType.hetuScript ||
              sourceType == ResourceType.hetuLiteralCode) {
            parseStyle = ParseStyle.script;
          } else if (sourceType == ResourceType.hetuValue) {
            parseStyle = ParseStyle.expression;
          } else {
            return nodes;
          }
        } else {
          parseStyle = ParseStyle.script;
        }
      }
      final stmt = _parseStmt(sourceType: parseStyle);
      if (stmt != null) {
        nodes.add(stmt);
      }
    }
    if (nodes.isEmpty) {
      final empty = EmptyExpr(
          source: _currentSource,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.end);
      empty.precedingComments.addAll(_currentPrecedingComments);
      _currentPrecedingComments.clear();
      nodes.add(empty);
    }
    return nodes;
  }

  List<AstNode> parse(String content, {HTSource? source}) {
    final tokens = HTLexer().lex(content);
    final nodes = parseToken(tokens, source: source);
    return nodes;
  }

  HTSourceParseResult parseSource(HTSource source) {
    _currrentFileName = source.fullName;
    _currentClass = null;
    _currentFunctionCategory = null;
    final nodes = parse(source.content, source: source);
    final result = HTSourceParseResult(source, nodes,
        imports: _currentModuleImports.toList(),
        errors: errors); // copy the list);
    _currentModuleImports.clear();
    return result;
  }

  /// Parse a string content and generate a library,
  /// will import other files.
  HTModuleParseResult parseToModule(HTSource source, {String? moduleName}) {
    _currentModuleName = moduleName ?? source.fullName;
    final result = parseSource(source);
    final moduleErrors = result.errors!;
    final values = <String, HTSourceParseResult>{};
    final sources = <String, HTSourceParseResult>{};

    void handleImport(HTSourceParseResult result) {
      _cachedRecursiveParsingTargets.add(result.fullName);
      for (final decl in result.imports) {
        try {
          late final HTSourceParseResult importModule;
          final currentDir =
              result.fullName.startsWith(Semantic.anonymousScript)
                  ? sourceContext.root
                  : path.dirname(result.fullName);
          final importFullName = sourceContext.getAbsolutePath(
              key: decl.fromPath!, dirName: currentDir);
          decl.fullName = importFullName;
          if (_cachedRecursiveParsingTargets.contains(importFullName)) {
            continue;
          } else if (_cachedParseResults.containsKey(importFullName)) {
            importModule = _cachedParseResults[importFullName]!;
          } else {
            final source2 = sourceContext.getResource(importFullName);
            importModule = parseSource(source2);
            moduleErrors.addAll(importModule.errors!);
            _cachedParseResults[importFullName] = importModule;
          }
          if (importModule.type == ResourceType.hetuValue) {
            values[importFullName] = importModule;
          } else {
            handleImport(importModule);
            sources[importFullName] = importModule;
          }
        } catch (error) {
          final convertedError = HTError.sourceProviderError(decl.fromPath!,
              filename: source.fullName,
              line: decl.line,
              column: decl.column,
              offset: decl.offset,
              length: decl.length);
          moduleErrors.add(convertedError);
        }
      }
      _cachedRecursiveParsingTargets.remove(result.fullName);
    }

    if (result.type == ResourceType.hetuValue) {
      values[result.fullName] = result;
    } else {
      handleImport(result);
      sources[result.fullName] = result;
    }
    final compilation = HTModuleParseResult(
        values: values,
        sources: sources,
        type: source.type,
        errors: moduleErrors);
    return compilation;
  }

  void _handleComment() {
    if (curTok.type == Semantic.singleLineComment) {
      final token = advance(1);
      final comment = Comment(token.literal,
          isMultiline: false,
          isDocumentation: token.lexeme
              .startsWith(HTLexicon.singleLineCommentDocumentationPattern));
      _currentPrecedingComments.add(comment);
    } else if (curTok.type == Semantic.multiLineComment) {
      final token = advance(1);
      final comment = Comment(token.literal,
          isMultiline: true,
          isDocumentation: token.lexeme
              .startsWith(HTLexicon.multiLineCommentDocumentationPattern));
      _currentPrecedingComments.add(comment);
    }
  }

  AstNode? _parseStmt({ParseStyle sourceType = ParseStyle.functionDefinition}) {
    if (curTok.type == Semantic.singleLineComment ||
        curTok.type == Semantic.multiLineComment) {
      _handleComment();
      return null;
    }

    AstNode stmt;
    final precedingCommentsOfThisStmt =
        List<Comment>.from(_currentPrecedingComments);
    _currentPrecedingComments.clear();
    if (curTok.type == HTLexicon.semicolon ||
        curTok.type == Semantic.emptyLine) {
      advance(1);
      final empty = advance(1);
      stmt = EmptyExpr(
          line: empty.line, column: empty.column, offset: empty.offset);
    } else {
      switch (sourceType) {
        case ParseStyle.script:
          if (curTok.lexeme == HTLexicon.kImport) {
            stmt = _parseImportDecl();
          } else if (curTok.lexeme == HTLexicon.kExport) {
            stmt = _parseExportStmt();
          } else if (curTok.lexeme == HTLexicon.kType) {
            stmt = _parseTypeAliasDecl();
          } else {
            switch (curTok.type) {
              case HTLexicon.kNamespace:
                stmt = _parseNamespaceDecl(isTopLevel: true);
                break;
              case HTLexicon.kAssert:
                stmt = _parseAssertStmt();
                break;
              case HTLexicon.kExternal:
                advance(1);
                switch (curTok.type) {
                  case HTLexicon.kAbstract:
                    advance(1);
                    stmt = _parseClassDecl(
                        isAbstract: true, isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kClass:
                    stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kEnum:
                    stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kVar:
                  case HTLexicon.kFinal:
                  case HTLexicon.kConst:
                    final err = HTError.externalVar(
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance(1);
                    stmt = EmptyExpr(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                    break;
                  case HTLexicon.kFun:
                    stmt = _parseFunction(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kAsync:
                    stmt = _parseFunction(
                        isAsync: true, isExternal: true, isTopLevel: true);
                    break;
                  default:
                    final err = HTError.unexpected(
                        Semantic.declStmt, curTok.lexeme,
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance(1);
                    stmt = EmptyExpr(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                }
                break;
              case HTLexicon.kAbstract:
                advance(1);
                stmt = _parseClassDecl(isAbstract: true, isTopLevel: true);
                break;
              case HTLexicon.kEnum:
                stmt = _parseEnumDecl(isTopLevel: true);
                break;
              case HTLexicon.kClass:
                stmt = _parseClassDecl(isTopLevel: true);
                break;
              case HTLexicon.kVar:
                stmt = _parseVarDecl(isMutable: true, isTopLevel: true);
                break;
              case HTLexicon.kFinal:
                stmt = _parseVarDecl(isTopLevel: true);
                break;
              case HTLexicon.kLate:
                stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
                break;
              case HTLexicon.kConst:
                stmt = _parseConstDecl(isTopLevel: true);
                break;
              case HTLexicon.kFun:
                if (expect([HTLexicon.kFun, Semantic.identifier]) ||
                    expect([
                      HTLexicon.kFun,
                      HTLexicon.bracketsLeft,
                      Semantic.identifier,
                      HTLexicon.bracketsRight,
                      Semantic.identifier
                    ])) {
                  stmt = _parseFunction(isTopLevel: true);
                } else {
                  stmt = _parseFunction(
                      category: FunctionCategory.literal, isTopLevel: true);
                }
                break;
              case HTLexicon.kAsync:
                if (expect([HTLexicon.kAsync, Semantic.identifier]) ||
                    expect([
                      HTLexicon.kFun,
                      HTLexicon.bracketsLeft,
                      Semantic.identifier,
                      HTLexicon.bracketsRight,
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
              case HTLexicon.kStruct:
                stmt =
                    _parseStructDecl(isTopLevel: true, lateInitialize: false);
                break;
              case HTLexicon.kDelete:
                stmt = _parseDeleteStmt();
                break;
              case HTLexicon.kIf:
                stmt = _parseIf();
                break;
              case HTLexicon.kWhile:
                stmt = _parseWhileStmt();
                break;
              case HTLexicon.kDo:
                stmt = _parseDoStmt();
                break;
              case HTLexicon.kFor:
                stmt = _parseForStmt();
                break;
              case HTLexicon.kWhen:
                stmt = _parseWhen();
                break;
              default:
                stmt = _parseExprStmt();
            }
          }
          break;
        case ParseStyle.module:
          if (curTok.lexeme == HTLexicon.kImport) {
            stmt = _parseImportDecl();
          } else if (curTok.lexeme == HTLexicon.kExport) {
            stmt = _parseExportStmt();
          } else if (curTok.lexeme == HTLexicon.kType) {
            stmt = _parseTypeAliasDecl(isTopLevel: true);
          } else {
            switch (curTok.type) {
              case HTLexicon.kNamespace:
                stmt = _parseNamespaceDecl(isTopLevel: true);
                break;
              case HTLexicon.kExternal:
                advance(1);
                switch (curTok.type) {
                  case HTLexicon.kAbstract:
                    advance(1);
                    if (curTok.type != HTLexicon.kClass) {
                      final err = HTError.unexpected(
                          Semantic.classDeclaration, curTok.lexeme,
                          filename: _currrentFileName,
                          line: curTok.line,
                          column: curTok.column,
                          offset: curTok.offset,
                          length: curTok.length);
                      errors?.add(err);
                      final errToken = advance(1);
                      stmt = EmptyExpr(
                          source: _currentSource,
                          line: errToken.line,
                          column: errToken.column,
                          offset: errToken.offset);
                    } else {
                      stmt = _parseClassDecl(
                          isAbstract: true, isExternal: true, isTopLevel: true);
                    }
                    break;
                  case HTLexicon.kClass:
                    stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kEnum:
                    stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kFun:
                    stmt = _parseFunction(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kVar:
                  case HTLexicon.kFinal:
                  case HTLexicon.kLate:
                  case HTLexicon.kConst:
                    final err = HTError.externalVar(
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance(1);
                    stmt = EmptyExpr(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                    break;
                  default:
                    final err = HTError.unexpected(
                        Semantic.declStmt, curTok.lexeme,
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance(1);
                    stmt = EmptyExpr(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                }
                break;
              case HTLexicon.kAbstract:
                advance(1);
                stmt = _parseClassDecl(isAbstract: true, isTopLevel: true);
                break;
              case HTLexicon.kEnum:
                stmt = _parseEnumDecl(isTopLevel: true);
                break;
              case HTLexicon.kClass:
                stmt = _parseClassDecl(isTopLevel: true);
                break;
              case HTLexicon.kVar:
                stmt = _parseVarDecl(
                    isMutable: true, isTopLevel: true, lateInitialize: true);
                break;
              case HTLexicon.kFinal:
                stmt = _parseVarDecl(lateInitialize: true, isTopLevel: true);
                break;
              case HTLexicon.kLate:
                stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
                break;
              case HTLexicon.kConst:
                stmt = _parseConstDecl(isTopLevel: true);
                break;
              case HTLexicon.kFun:
                stmt = _parseFunction(isTopLevel: true);
                break;
              case HTLexicon.kStruct:
                stmt = _parseStructDecl(isTopLevel: true);
                break;
              default:
                final err = HTError.unexpected(Semantic.declStmt, curTok.lexeme,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
            }
          }
          break;
        case ParseStyle.namespace:
          if (curTok.lexeme == HTLexicon.kType) {
            stmt = _parseTypeAliasDecl();
          } else {
            switch (curTok.type) {
              case HTLexicon.kNamespace:
                stmt = _parseNamespaceDecl();
                break;
              case HTLexicon.kAssert:
                stmt = _parseAssertStmt();
                break;
              case HTLexicon.kExternal:
                advance(1);
                switch (curTok.type) {
                  case HTLexicon.kAbstract:
                    advance(1);
                    if (curTok.type != HTLexicon.kClass) {
                      final err = HTError.unexpected(
                          Semantic.classDeclaration, curTok.lexeme,
                          filename: _currrentFileName,
                          line: curTok.line,
                          column: curTok.column,
                          offset: curTok.offset,
                          length: curTok.length);
                      errors?.add(err);
                      final errToken = advance(1);
                      stmt = EmptyExpr(
                          source: _currentSource,
                          line: errToken.line,
                          column: errToken.column,
                          offset: errToken.offset);
                    } else {
                      stmt =
                          _parseClassDecl(isAbstract: true, isExternal: true);
                    }
                    break;
                  case HTLexicon.kClass:
                    stmt = _parseClassDecl(isExternal: true);
                    break;
                  case HTLexicon.kEnum:
                    stmt = _parseEnumDecl(isExternal: true);
                    break;
                  case HTLexicon.kFun:
                    stmt = _parseFunction(isExternal: true);
                    break;
                  case HTLexicon.kVar:
                  case HTLexicon.kFinal:
                  case HTLexicon.kLate:
                  case HTLexicon.kConst:
                    final err = HTError.externalVar(
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance(1);
                    stmt = EmptyExpr(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                    break;
                  default:
                    final err = HTError.unexpected(
                        Semantic.declStmt, curTok.lexeme,
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance(1);
                    stmt = EmptyExpr(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                }
                break;
              case HTLexicon.kAbstract:
                advance(1);
                stmt = _parseClassDecl(isAbstract: true);
                break;
              case HTLexicon.kEnum:
                stmt = _parseEnumDecl();
                break;
              case HTLexicon.kClass:
                stmt = _parseClassDecl();
                break;
              case HTLexicon.kVar:
                stmt = _parseVarDecl(isMutable: true, lateInitialize: true);
                break;
              case HTLexicon.kFinal:
                stmt = _parseVarDecl(lateInitialize: true);
                break;
              case HTLexicon.kLate:
                stmt = _parseVarDecl(lateFinalize: true);
                break;
              case HTLexicon.kConst:
                stmt = _parseConstDecl();
                break;
              case HTLexicon.kFun:
                stmt = _parseFunction();
                break;
              case HTLexicon.kStruct:
                stmt = _parseStructDecl();
                break;
              default:
                final err = HTError.unexpected(Semantic.declStmt, curTok.lexeme,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
            }
          }
          break;
        case ParseStyle.classDefinition:
          final isOverrided = expect([HTLexicon.kOverride], consume: true);
          final isExternal = expect([HTLexicon.kExternal], consume: true) ||
              (_currentClass?.isExternal ?? false);
          final isStatic = expect([HTLexicon.kStatic], consume: true);
          if (curTok.lexeme == HTLexicon.kType) {
            if (isExternal) {
              final err = HTError.external(Semantic.typeAliasDeclaration,
                  filename: _currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance(1);
              stmt = EmptyExpr(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              stmt = _parseTypeAliasDecl();
            }
          } else {
            switch (curTok.type) {
              case HTLexicon.kVar:
                stmt = _parseVarDecl(
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isMutable: true,
                    isStatic: isStatic,
                    lateInitialize: true);
                break;
              case HTLexicon.kFinal:
                stmt = _parseVarDecl(
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic,
                    lateInitialize: true);
                break;
              case HTLexicon.kLate:
                stmt = _parseVarDecl(
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic,
                    lateFinalize: true);
                break;
              case HTLexicon.kConst:
                if (isStatic) {
                  stmt = _parseConstDecl(
                      classId: _currentClass?.id, isStatic: isStatic);
                } else {
                  final err = HTError.external(Semantic.typeAliasDeclaration,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                }
                break;
              case HTLexicon.kFun:
                stmt = _parseFunction(
                    category: FunctionCategory.method,
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic);
                break;
              case HTLexicon.kAsync:
                if (isExternal) {
                  final err = HTError.external(Semantic.asyncFunction,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
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
              case HTLexicon.kGet:
                stmt = _parseFunction(
                    category: FunctionCategory.getter,
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic);
                break;
              case HTLexicon.kSet:
                stmt = _parseFunction(
                    category: FunctionCategory.setter,
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic);
                break;
              case HTLexicon.kConstruct:
                if (isStatic) {
                  final err = HTError.unexpected(
                      Semantic.declStmt, HTLexicon.kConstruct,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                } else if (isExternal && !_currentClass!.isExternal) {
                  final err = HTError.external(Semantic.ctorFunction,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
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
              case HTLexicon.kFactory:
                if (isStatic) {
                  final err = HTError.unexpected(
                      Semantic.declStmt, HTLexicon.kConstruct,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                } else if (isExternal && !_currentClass!.isExternal) {
                  final err = HTError.external(Semantic.factory,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
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
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
            }
          }
          break;
        case ParseStyle.structDefinition:
          final isExternal = expect([HTLexicon.kExternal], consume: true);
          final isStatic = expect([HTLexicon.kStatic], consume: true);
          switch (curTok.type) {
            case HTLexicon.kVar:
              stmt = _parseVarDecl(
                  classId: _currentStructId,
                  isField: true,
                  isExternal: isExternal,
                  isMutable: true,
                  isStatic: isStatic,
                  lateInitialize: true);
              break;
            case HTLexicon.kFinal:
              stmt = _parseVarDecl(
                  classId: _currentStructId,
                  isField: true,
                  isExternal: isExternal,
                  isStatic: isStatic,
                  lateInitialize: true);
              break;
            case HTLexicon.kFun:
              stmt = _parseFunction(
                  category: FunctionCategory.method,
                  classId: _currentStructId,
                  isExternal: isExternal,
                  isField: true,
                  isStatic: isStatic);
              break;
            case HTLexicon.kAsync:
              if (isExternal) {
                final err = HTError.external(Semantic.asyncFunction,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
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
            case HTLexicon.kGet:
              stmt = _parseFunction(
                  category: FunctionCategory.getter,
                  classId: _currentStructId,
                  isField: true,
                  isExternal: isExternal,
                  isStatic: isStatic);
              break;
            case HTLexicon.kSet:
              stmt = _parseFunction(
                  category: FunctionCategory.setter,
                  classId: _currentStructId,
                  isField: true,
                  isExternal: isExternal,
                  isStatic: isStatic);
              break;
            case HTLexicon.kConstruct:
              if (isStatic) {
                final err = HTError.unexpected(
                    Semantic.declStmt, HTLexicon.kConstruct,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else if (isExternal) {
                final err = HTError.external(Semantic.ctorFunction,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
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
                  filename: _currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance(1);
              stmt = EmptyExpr(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
          }
          break;
        case ParseStyle.functionDefinition:
          switch (curTok.type) {
            case HTLexicon.kNamespace:
              stmt = _parseNamespaceDecl();
              break;
            case HTLexicon.kAssert:
              stmt = _parseAssertStmt();
              break;
            case HTLexicon.kAbstract:
              advance(1);
              stmt = _parseClassDecl(isAbstract: true);
              break;
            case HTLexicon.kEnum:
              stmt = _parseEnumDecl();
              break;
            case HTLexicon.kClass:
              stmt = _parseClassDecl();
              break;
            case HTLexicon.kVar:
              stmt = _parseVarDecl(isMutable: true);
              break;
            case HTLexicon.kFinal:
              stmt = _parseVarDecl();
              break;
            case HTLexicon.kLate:
              stmt = _parseVarDecl(lateFinalize: true);
              break;
            case HTLexicon.kConst:
              stmt = _parseConstDecl();
              break;
            case HTLexicon.kFun:
              if (expect([HTLexicon.kFun, Semantic.identifier]) ||
                  expect([
                    HTLexicon.kFun,
                    HTLexicon.bracketsLeft,
                    Semantic.identifier,
                    HTLexicon.bracketsRight,
                    Semantic.identifier
                  ])) {
                stmt = _parseFunction();
              } else {
                stmt = _parseFunction(category: FunctionCategory.literal);
              }
              break;
            case HTLexicon.kAsync:
              if (expect([HTLexicon.kAsync, Semantic.identifier]) ||
                  expect([
                    HTLexicon.kFun,
                    HTLexicon.bracketsLeft,
                    Semantic.identifier,
                    HTLexicon.bracketsRight,
                    Semantic.identifier
                  ])) {
                stmt = _parseFunction(isAsync: true);
              } else {
                stmt = _parseFunction(
                    category: FunctionCategory.literal, isAsync: true);
              }
              break;
            case HTLexicon.kStruct:
              stmt = _parseStructDecl(lateInitialize: false);
              break;
            case HTLexicon.kDelete:
              stmt = _parseDeleteStmt();
              break;
            case HTLexicon.kIf:
              stmt = _parseIf();
              break;
            case HTLexicon.kWhile:
              stmt = _parseWhileStmt();
              break;
            case HTLexicon.kDo:
              stmt = _parseDoStmt();
              break;
            case HTLexicon.kFor:
              stmt = _parseForStmt();
              break;
            case HTLexicon.kWhen:
              stmt = _parseWhen();
              break;
            case HTLexicon.kBreak:
              final keyword = advance(1);
              final hasEndOfStmtMark =
                  expect([HTLexicon.semicolon], consume: true);
              stmt = BreakStmt(keyword,
                  hasEndOfStmtMark: hasEndOfStmtMark,
                  source: _currentSource,
                  line: keyword.line,
                  column: keyword.column,
                  offset: keyword.offset,
                  length: keyword.length);
              break;
            case HTLexicon.kContinue:
              final keyword = advance(1);
              final hasEndOfStmtMark =
                  expect([HTLexicon.semicolon], consume: true);
              stmt = ContinueStmt(keyword,
                  hasEndOfStmtMark: hasEndOfStmtMark,
                  source: _currentSource,
                  line: keyword.line,
                  column: keyword.column,
                  offset: keyword.offset,
                  length: keyword.length);
              break;
            case HTLexicon.kReturn:
              if (_currentFunctionCategory != null &&
                  _currentFunctionCategory != FunctionCategory.constructor) {
                stmt = _parseReturnStmt();
              } else {
                final err = HTError.outsideReturn(
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
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
    }

    if (stmt.isStatement) {
      stmt.precedingComments.addAll(precedingCommentsOfThisStmt);
      _currentPrecedingComments.clear();
    }

    if (curTok.type == Semantic.consumingLineEndComment) {
      final token = advance(1);
      stmt.consumingLineEndComment = Comment(token.literal);
    }

    return stmt;
  }

  AssertStmt _parseAssertStmt() {
    final keyword = match(HTLexicon.kAssert);
    match(HTLexicon.parenthesesLeft);
    final expr = _parseExpr();
    match(HTLexicon.parenthesesRight);
    expect([HTLexicon.semicolon], consume: true);
    final stmt = AssertStmt(expr,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: expr.end - keyword.offset);
    return stmt;
  }

  /// 使用递归向下的方法生成表达式, 不断调用更底层的, 优先级更高的子Parser
  ///
  /// 赋值 = , 优先级 1, 右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  AstNode _parseExpr() {
    while (curTok.type == Semantic.singleLineComment ||
        curTok.type == Semantic.multiLineComment) {
      _handleComment();
    }
    AstNode? expr;
    final left = _parserTernaryExpr();
    if (HTLexicon.assignments.contains(curTok.type)) {
      if (!_leftValueLegality) {
        final err = HTError.invalidLeftValue(
            filename: _currrentFileName,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: left.length);
        errors?.add(err);
      }
      final op = advance(1);
      final right = _parseExpr();
      if (op.type == HTLexicon.assign) {
        if (left is MemberExpr) {
          if (left.isNullable) {
            final err = HTError.nullableAssign(
                filename: _currrentFileName,
                line: left.line,
                column: left.column,
                offset: left.offset,
                length: left.length);
            errors?.add(err);
          }
          expr = MemberAssignExpr(left.object, left.key, right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else if (left is SubExpr) {
          if (left.isNullable) {
            final err = HTError.nullableAssign(
                filename: _currrentFileName,
                line: left.line,
                column: left.column,
                offset: left.offset,
                length: left.length);
            errors?.add(err);
          }
          expr = SubAssignExpr(left.object, left.key, right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else {
          expr = BinaryExpr(left, op.lexeme, right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        }
      } else if (op.type == HTLexicon.assignIfNull) {
        if (left is MemberExpr) {
          if (left.isNullable) {
            final err = HTError.nullableAssign(
                filename: _currrentFileName,
                line: left.line,
                column: left.column,
                offset: left.offset,
                length: left.length);
            errors?.add(err);
          }
          expr = IfStmt(
            BinaryExpr(
              left,
              HTLexicon.equal,
              NullExpr(),
            ),
            MemberAssignExpr(
              left.object,
              left.key,
              right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset,
            ),
          );
        } else if (left is SubExpr) {
          if (left.isNullable) {
            final err = HTError.nullableAssign(
                filename: _currrentFileName,
                line: left.line,
                column: left.column,
                offset: left.offset,
                length: left.length);
            errors?.add(err);
          }
          expr = IfStmt(
            BinaryExpr(
              left,
              HTLexicon.equal,
              NullExpr(),
            ),
            SubAssignExpr(
              left.object,
              left.key,
              right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset,
            ),
          );
        } else {
          expr = IfStmt(
            BinaryExpr(
              left,
              HTLexicon.equal,
              NullExpr(),
            ),
            BinaryExpr(
              left,
              HTLexicon.assign,
              right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset,
            ),
          );
        }
      } else {
        if (left is MemberExpr) {
          if (left.isNullable) {
            final err = HTError.nullableAssign(
                filename: _currrentFileName,
                line: left.line,
                column: left.column,
                offset: left.offset,
                length: left.length);
            errors?.add(err);
          }
          expr = MemberAssignExpr(
              left.object,
              left.key,
              BinaryExpr(
                  left, op.lexeme.substring(0, op.lexeme.length - 1), right),
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else if (left is SubExpr) {
          if (left.isNullable) {
            final err = HTError.nullableAssign(
                filename: _currrentFileName,
                line: left.line,
                column: left.column,
                offset: left.offset,
                length: left.length);
            errors?.add(err);
          }
          expr = SubAssignExpr(
              left.object,
              left.key,
              BinaryExpr(
                  left, op.lexeme.substring(0, op.lexeme.length - 1), right),
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else {
          expr = BinaryExpr(
              left,
              HTLexicon.assign,
              BinaryExpr(
                  left, op.lexeme.substring(0, op.lexeme.length - 1), right),
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        }
      }
    } else {
      expr = left;
    }

    expr.precedingComments.addAll(_currentPrecedingComments);
    _currentPrecedingComments.clear();

    if (curTok.type == Semantic.consumingLineEndComment) {
      final token = advance(1);
      expr.consumingLineEndComment = Comment(token.literal);
    }

    return expr;
  }

  /// Ternery operator: e1 ? e2 : e3, precedence 3, associativity right
  AstNode _parserTernaryExpr() {
    var condition = _parseIfNullExpr();
    if (expect([HTLexicon.condition], consume: true)) {
      _leftValueLegality = false;
      final thenBranch = _parserTernaryExpr();
      match(HTLexicon.colon);
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
  AstNode _parseIfNullExpr() {
    var left = _parseLogicalOrExpr();
    if (curTok.type == HTLexicon.ifNull) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.ifNull) {
        final op = advance(1);
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

  /// Logical or: || , precedence 5, associativity left
  AstNode _parseLogicalOrExpr() {
    var left = _parseLogicalAndExpr();
    if (curTok.type == HTLexicon.logicalOr) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalOr) {
        final op = advance(1);
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

  /// 逻辑和 && , 优先级 6, 左合并
  AstNode _parseLogicalAndExpr() {
    var left = _parseEqualityExpr();
    if (curTok.type == HTLexicon.logicalAnd) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalAnd) {
        final op = advance(1);
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

  /// 逻辑相等 ==, !=, 优先级 7, 不合并
  AstNode _parseEqualityExpr() {
    var left = _parseRelationalExpr();
    if (HTLexicon.equalitys.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
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

  /// 逻辑比较 <, >, <=, >=, as, is, is! 优先级 8, 不合并
  AstNode _parseRelationalExpr() {
    var left = _parseAdditiveExpr();
    if (HTLexicon.logicalRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: _currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (HTLexicon.typeRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
      late final String opLexeme;
      if (op.lexeme == HTLexicon.kIs) {
        opLexeme = expect([HTLexicon.logicalNot], consume: true)
            ? HTLexicon.kIsNot
            : HTLexicon.kIs;
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

  /// 加法 +, -, 优先级 13, 左合并
  AstNode _parseAdditiveExpr() {
    var left = _parseMultiplicativeExpr();
    if (HTLexicon.additives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.additives.contains(curTok.type)) {
        final op = advance(1);
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

  /// 乘法 *, /, ~/, %, 优先级 14, 左合并
  AstNode _parseMultiplicativeExpr() {
    var left = _parseUnaryPrefixExpr();
    if (HTLexicon.multiplicatives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.multiplicatives.contains(curTok.type)) {
        final op = advance(1);
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

  /// 前缀 -e, !e，++e, --e, 优先级 15, 不合并
  AstNode _parseUnaryPrefixExpr() {
    if (!(HTLexicon.unaryPrefixs.contains(curTok.type))) {
      return _parseUnaryPostfixExpr();
    } else {
      final op = advance(1);
      final value = _parseUnaryPostfixExpr();
      return UnaryPrefixExpr(op.lexeme, value,
          source: _currentSource,
          line: op.line,
          column: op.column,
          offset: op.offset,
          length: curTok.offset - op.offset);
    }
  }

  /// 后缀 e., e?., e[], e?[], e(), e?(), e++, e-- 优先级 16, 右合并
  AstNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    while (HTLexicon.unaryPostfixs.contains(curTok.type)) {
      final op = advance(1);
      switch (op.type) {
        case HTLexicon.memberGet:
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
        case HTLexicon.nullableMemberGet:
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
        case HTLexicon.subGet:
          var isNullable = false;
          if ((expr is MemberExpr && expr.isNullable) ||
              (expr is SubExpr && expr.isNullable) ||
              (expr is CallExpr && expr.isNullable)) {
            isNullable = true;
          }
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(HTLexicon.bracketsRight);
          expr = SubExpr(expr, indexExpr,
              isNullable: isNullable,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.nullableSubGet:
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(HTLexicon.bracketsRight);
          expr = SubExpr(expr, indexExpr,
              isNullable: true,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.nullableCall:
          _leftValueLegality = false;
          var positionalArgs = <AstNode>[];
          var namedArgs = <String, AstNode>{};
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
        case HTLexicon.call:
          var isNullable = false;
          if ((expr is MemberExpr && expr.isNullable) ||
              (expr is SubExpr && expr.isNullable) ||
              (expr is CallExpr && expr.isNullable)) {
            isNullable = true;
          }
          _leftValueLegality = false;
          var positionalArgs = <AstNode>[];
          var namedArgs = <String, AstNode>{};
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
        case HTLexicon.postIncrement:
        case HTLexicon.postDecrement:
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

  /// Expression without operators
  AstNode _parsePrimaryExpr() {
    switch (curTok.type) {
      case HTLexicon.kNull:
        _leftValueLegality = false;
        final token = advance(1);
        return NullExpr(
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.booleanLiteral:
        _leftValueLegality = false;
        final token = match(Semantic.booleanLiteral) as TokenBooleanLiteral;
        return BooleanLiteralExpr(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.integerLiteral:
        _leftValueLegality = false;
        final token = match(Semantic.integerLiteral) as TokenIntLiteral;
        return IntLiteralExpr(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.floatLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenFloatLiteral;
        return FloatLiteralExpr(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.stringLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenStringLiteral;
        return StringLiteralExpr(
            token.literal, token.quotationLeft, token.quotationRight,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.stringInterpolation:
        _leftValueLegality = false;
        final token = advance(1) as TokenStringInterpolation;
        final interpolation = <AstNode>[];
        for (final tokens in token.interpolations) {
          final exprParser = HTParser(context: sourceContext);
          final nodes = exprParser.parseToken(tokens,
              source: _currentSource, style: ParseStyle.expression);
          errors?.addAll(exprParser.errors!);
          if (nodes.length > 1) {
            final err = HTError.stringInterpolation(
                filename: _currrentFileName,
                line: nodes.first.line,
                column: nodes.first.column,
                offset: nodes.first.offset,
                length: nodes.last.end - nodes.first.offset);
            errors?.add(err);
            final errNode = EmptyExpr(
                source: _currentSource,
                line: token.line,
                column: token.column,
                offset: token.offset);
            interpolation.add(errNode);
          } else {
            // parser will at least insert a empty line astnode
            if (nodes.first is EmptyExpr) {
              final err = HTError.stringInterpolation(
                  filename: _currrentFileName,
                  line: nodes.first.line,
                  column: nodes.first.column,
                  offset: nodes.first.offset,
                  length: nodes.first.length +
                      HTLexicon.stringInterpolationStart.length +
                      HTLexicon.stringInterpolationEnd.length);
              errors?.add(err);
            }
            interpolation.add(nodes.first);
          }
        }
        var i = 0;
        final value = token.literal.replaceAllMapped(
            RegExp(HTLexicon.stringInterpolationPattern),
            (Match m) =>
                '${HTLexicon.bracesLeft}${i++}${HTLexicon.bracesRight}');
        return StringInterpolationExpr(
            value, token.quotationLeft, token.quotationRight, interpolation,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case HTLexicon.kThis:
        _leftValueLegality = false;
        final keyword = advance(1);
        return IdentifierExpr(keyword.lexeme,
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length,
            isKeyword: true);
      case HTLexicon.kSuper:
        _leftValueLegality = false;
        final keyword = advance(1);
        return IdentifierExpr(keyword.lexeme,
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length,
            isKeyword: true);
      case HTLexicon.kIf:
        return _parseIf(isExpression: true);
      case HTLexicon.kWhen:
        return _parseWhen(isExpression: true);
      case HTLexicon.parenthesesLeft:
        _leftValueLegality = false;
        // a literal function expression
        final token = seekGroupClosing();
        if (token.type == HTLexicon.bracesLeft ||
            token.type == HTLexicon.doubleArrow) {
          return _parseFunction(
              category: FunctionCategory.literal, hasKeyword: false);
        }
        // a group expression
        else {
          final start = advance(1);
          final innerExpr = _parseExpr();
          final end = match(HTLexicon.parenthesesRight);
          return GroupExpr(innerExpr,
              source: _currentSource,
              line: start.line,
              column: start.column,
              offset: start.offset,
              length: end.offset + end.length - start.offset);
        }
      case HTLexicon.bracketsLeft:
        _leftValueLegality = false;
        final start = advance(1);
        var listExpr = <AstNode>[];
        while (curTok.type != HTLexicon.bracketsRight &&
            curTok.type != Semantic.endOfFile) {
          AstNode item;
          if (curTok.type == HTLexicon.spreadSyntax) {
            final spreadTok = advance(1);
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
          if (curTok.type != HTLexicon.bracketsRight) {
            match(HTLexicon.comma);
          }
          if (curTok.type == Semantic.consumingLineEndComment) {
            final token = advance(1);
            item.consumingLineEndComment = Comment(token.literal);
          }
        }
        final end = match(HTLexicon.bracketsRight);
        return ListExpr(listExpr,
            source: _currentSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: end.end - start.offset);
      case HTLexicon.bracesLeft:
        return _parseStructObj();
      case HTLexicon.kStruct:
        return _parseStructObj(hasKeyword: true);
      case HTLexicon.kFun:
        return _parseFunction(category: FunctionCategory.literal);
      case Semantic.identifier:
        _leftValueLegality = true;
        final id = advance(1);
        final isLocal = curTok.type != HTLexicon.assign;
        // TODO: type arguments
        return IdentifierExpr.fromToken(id,
            isLocal: isLocal, source: _currentSource);
      default:
        final err = HTError.unexpected(Semantic.expression, curTok.lexeme,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
        final errToken = advance(1);
        return EmptyExpr(
            source: _currentSource,
            line: errToken.line,
            column: errToken.column,
            offset: errToken.offset);
    }
  }

  TypeExpr _parseTypeExpr({bool isLocal = false}) {
    // function type
    if (curTok.type == HTLexicon.parenthesesLeft) {
      final startTok = advance(1);
      // TODO: genericTypeParameters 泛型参数
      final parameters = <ParamTypeExpr>[];
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while (curTok.type != HTLexicon.parenthesesRight &&
          curTok.type != Semantic.endOfFile) {
        final start = curTok;
        if (!isOptional) {
          isOptional = expect([HTLexicon.bracketsLeft], consume: true);
          if (!isOptional && !isNamed) {
            isNamed = expect([HTLexicon.bracesLeft], consume: true);
          }
        }
        late final TypeExpr paramType;
        IdentifierExpr? paramSymbol;
        if (!isNamed) {
          isVariadic = expect([HTLexicon.variadicArgs], consume: true);
        } else {
          final paramId = match(Semantic.identifier);
          paramSymbol =
              IdentifierExpr.fromToken(paramId, source: _currentSource);
          match(HTLexicon.colon);
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
        if (isOptional && expect([HTLexicon.bracketsRight], consume: true)) {
          break;
        } else if (isNamed && expect([HTLexicon.bracesRight], consume: true)) {
          break;
        } else if (curTok.type != HTLexicon.parenthesesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == Semantic.consumingLineEndComment) {
          final token = advance(1);
          param.consumingLineEndComment = Comment(token.literal);
        }
        parameters.add(param);
        if (isVariadic) {
          break;
        }
      }
      match(HTLexicon.parenthesesRight);
      match(HTLexicon.singleArrow);
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
    else if (curTok.type == HTLexicon.bracesLeft) {
      final startTok = advance(1);
      final fieldTypes = <FieldTypeExpr>[];
      while (curTok.type != HTLexicon.bracesRight &&
          curTok.type != Semantic.endOfFile) {
        late Token idTok;
        if (curTok.type == Semantic.stringLiteral) {
          idTok = advance(1);
        } else {
          idTok = match(Semantic.identifier);
        }
        match(HTLexicon.colon);
        final typeExpr = _parseTypeExpr();
        fieldTypes.add(FieldTypeExpr(idTok.literal, typeExpr));
        expect([HTLexicon.comma], consume: true);
      }
      match(HTLexicon.bracesRight);
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
      if (expect([HTLexicon.chevronsLeft], consume: true)) {
        if (curTok.type == HTLexicon.chevronsRight) {
          final err = HTError.emptyTypeArgs(
              filename: _currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.end - idTok.offset);
          errors?.add(err);
        }
        while ((curTok.type != HTLexicon.chevronsRight) &&
            (curTok.type != Semantic.endOfFile)) {
          final typeArg = _parseTypeExpr();
          expect([HTLexicon.comma], consume: true);
          if (curTok.type == Semantic.consumingLineEndComment) {
            final token = advance(1);
            typeArg.consumingLineEndComment = Comment(token.literal);
          }
          typeArgs.add(typeArg);
        }
        match(HTLexicon.chevronsRight);
      }
      final isNullable = expect([HTLexicon.nullable], consume: true);
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
    final startTok = match(HTLexicon.bracesLeft);
    final statements = <AstNode>[];
    while (curTok.type != HTLexicon.bracesRight &&
        curTok.type != Semantic.endOfFile) {
      final stmt = _parseStmt(sourceType: sourceType);
      if (stmt != null) {
        statements.add(stmt);
      }
    }
    final endTok = match(HTLexicon.bracesRight);
    if (statements.isEmpty) {
      final empty = EmptyExpr(
          source: _currentSource,
          line: endTok.line,
          column: endTok.column,
          offset: endTok.offset,
          length: endTok.offset - startTok.end);
      empty.precedingComments.addAll(_currentPrecedingComments);
      _currentPrecedingComments.clear();
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
      List<AstNode> positionalArgs, Map<String, AstNode> namedArgs) {
    var isNamed = false;
    while ((curTok.type != HTLexicon.parenthesesRight) &&
        (curTok.type != Semantic.endOfFile)) {
      if ((!isNamed &&
              expect([Semantic.identifier, HTLexicon.colon], consume: false)) ||
          isNamed) {
        isNamed = true;
        final name = match(Semantic.identifier).lexeme;
        match(HTLexicon.colon);
        final namedArg = _parseExpr();
        if (curTok.type != HTLexicon.parenthesesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == Semantic.consumingLineEndComment) {
          final token = advance(1);
          namedArg.consumingLineEndComment = Comment(token.literal);
        }
        namedArgs[name] = namedArg;
      } else {
        late AstNode positionalArg;
        if (curTok.type == HTLexicon.spreadSyntax) {
          final spreadTok = advance(1);
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
        if (curTok.type != HTLexicon.parenthesesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == Semantic.consumingLineEndComment) {
          final token = advance(1);
          positionalArg.consumingLineEndComment = Comment(token.literal);
        }
        positionalArgs.add(positionalArg);
      }
    }
    match(HTLexicon.parenthesesRight);
  }

  AstNode _parseExprStmt() {
    final expr = _parseExpr();
    expect([HTLexicon.semicolon], consume: true);
    final stmt = ExprStmt(expr,
        source: _currentSource,
        line: expr.line,
        column: expr.column,
        offset: expr.offset,
        length: curTok.offset - expr.offset);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    AstNode? expr;
    if (curTok.type == HTLexicon.kSuper) {
      final err = HTError.unexpected(Semantic.expression, curTok.lexeme,
          filename: _currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors?.add(err);
      advance(1);
    } else {
      if (curTok.type != HTLexicon.bracesRight &&
          curTok.type != HTLexicon.semicolon &&
          curTok.type != Semantic.endOfFile) {
        expr = _parseExpr();
      }
    }
    final hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
    return ReturnStmt(keyword,
        value: expr,
        source: _currentSource,
        hasEndOfStmtMark: hasEndOfStmtMark,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  AstNode _parseExprOrStmtOrBlock({bool isExpression = false}) {
    if (curTok.type == HTLexicon.bracesLeft) {
      return _parseBlockStmt(id: Semantic.elseBranch);
    } else {
      if (isExpression) {
        return _parseExpr();
      } else {
        final startTok = curTok;
        var node = _parseStmt();
        if (node == null) {
          final err = HTError.unexpected(Semantic.expression, curTok.lexeme,
              filename: _currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors?.add(err);
          node = EmptyExpr(
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
    final keyword = match(HTLexicon.kIf);
    match(HTLexicon.parenthesesLeft);
    final condition = _parseExpr();
    match(HTLexicon.parenthesesRight);
    var thenBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
    _handleComment();
    AstNode? elseBranch;
    if (isExpression) {
      match(HTLexicon.kElse);
      elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
    } else {
      if (expect([HTLexicon.kElse], consume: true)) {
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
    final keyword = match(HTLexicon.kWhile);
    match(HTLexicon.parenthesesLeft);
    final condition = _parseExpr();
    match(HTLexicon.parenthesesRight);
    final loop = _parseBlockStmt(id: Semantic.whileLoop);
    return WhileStmt(condition, loop,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DoStmt _parseDoStmt() {
    final keyword = advance(1);
    final loop = _parseBlockStmt(id: Semantic.doLoop);
    AstNode? condition;
    if (expect([HTLexicon.kWhile], consume: true)) {
      match(HTLexicon.parenthesesLeft);
      condition = _parseExpr();
      match(HTLexicon.parenthesesRight);
    }
    return DoStmt(loop, condition,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  AstNode _parseForStmt() {
    final keyword = advance(1);
    final hasBracket = expect([HTLexicon.parenthesesLeft], consume: true);
    final forStmtType = peek(2).lexeme;
    VarDecl? decl;
    AstNode? condition;
    AstNode? increment;
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (forStmtType == HTLexicon.kIn || forStmtType == HTLexicon.kOf) {
      if (!HTLexicon.varDeclKeywords.contains(curTok.type)) {
        final err = HTError.unexpected(
            Semantic.variableDeclaration, curTok.type,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      decl = _parseVarDecl(
          // typeInferrence: curTok.type != HTLexicon.VAR,
          isMutable: curTok.type != HTLexicon.kFinal);
      advance(1);
      final collection = _parseExpr();
      if (hasBracket) {
        match(HTLexicon.parenthesesRight);
      }
      final loop = _parseBlockStmt(id: Semantic.forLoop);
      return ForRangeStmt(decl, collection, loop,
          hasBracket: hasBracket,
          iterateValue: forStmtType == HTLexicon.kOf,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      if (!expect([HTLexicon.semicolon], consume: false)) {
        decl = _parseVarDecl(
            // typeInferrence: curTok.type != HTLexicon.VAR,
            isMutable: curTok.type != HTLexicon.kFinal,
            hasEndOfStatement: true);
      } else {
        match(HTLexicon.semicolon);
      }
      if (!expect([HTLexicon.semicolon], consume: false)) {
        condition = _parseExpr();
      }
      match(HTLexicon.semicolon);
      if (!expect([HTLexicon.parenthesesRight], consume: false)) {
        increment = _parseExpr();
      }
      if (hasBracket) {
        match(HTLexicon.parenthesesRight);
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
    final keyword = advance(1);
    AstNode? condition;
    if (curTok.type != HTLexicon.bracesLeft) {
      match(HTLexicon.parenthesesLeft);
      condition = _parseExpr();
      match(HTLexicon.parenthesesRight);
    }
    final options = <AstNode, AstNode>{};
    AstNode? elseBranch;
    match(HTLexicon.bracesLeft);
    while (curTok.type != HTLexicon.bracesRight &&
        curTok.type != Semantic.endOfFile) {
      if (curTok.lexeme == HTLexicon.kElse) {
        advance(1);
        match(HTLexicon.singleArrow);
        elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
      } else {
        final caseExpr = _parseExpr();
        match(HTLexicon.singleArrow);
        var caseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
        options[caseExpr] = caseBranch;
      }
    }
    match(HTLexicon.bracesRight);
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
    if (expect([HTLexicon.chevronsLeft], consume: true)) {
      while ((curTok.type != HTLexicon.chevronsRight) &&
          (curTok.type != Semantic.endOfFile)) {
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
        final param = GenericTypeParameterExpr(id,
            source: _currentSource,
            line: idTok.line,
            column: idTok.column,
            offset: idTok.offset,
            length: curTok.offset - idTok.offset);
        if (curTok.type != HTLexicon.chevronsRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == Semantic.consumingLineEndComment) {
          final token = advance(1);
          param.consumingLineEndComment = Comment(token.literal);
        }
        genericParams.add(param);
      }
      match(HTLexicon.chevronsRight);
    }
    return genericParams;
  }

  ImportExportDecl _parseImportDecl() {
    // TODO: duplicate import and self import error.
    final keyword = advance(1); // not a keyword so don't use match
    final showList = <IdentifierExpr>[];
    if (curTok.type == HTLexicon.bracesLeft) {
      advance(1);
      if (curTok.type == HTLexicon.bracesRight) {
        final err = HTError.emptyImportList(
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.end - keyword.offset);
        errors?.add(err);
      }
      while (curTok.type != HTLexicon.bracesRight &&
          curTok.type != Semantic.endOfFile) {
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
        if (curTok.type != HTLexicon.bracesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == Semantic.consumingLineEndComment) {
          final token = advance(1);
          id.consumingLineEndComment = Comment(token.literal);
        }
        showList.add(id);
      }
      match(HTLexicon.bracesRight);
      // check lexeme here because expect() can only deal with token type
      final fromKeyword = advance(1).lexeme;
      if (fromKeyword != HTLexicon.kFrom) {
        final err = HTError.unexpected(HTLexicon.kFrom, curTok.lexeme,
            filename: _currrentFileName,
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
      hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
    }

    final fromPathTok = match(Semantic.stringLiteral);
    final ext = path.extension(fromPathTok.lexeme);
    if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
      if (showList.isNotEmpty) {
        final err = HTError.importListOnNonHetuSource(
            filename: _currrentFileName,
            line: fromPathTok.line,
            column: fromPathTok.column,
            offset: fromPathTok.offset,
            length: fromPathTok.length);
        errors?.add(err);
      }
      match(HTLexicon.kAs);
      _handleAlias();
    } else {
      hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
      if (!hasEndOfStmtMark && expect([HTLexicon.kAs], consume: true)) {
        _handleAlias();
      }
    }
    final stmt = ImportExportDecl(
        fromPath: fromPathTok.literal,
        showList: showList,
        alias: alias,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    _currentModuleImports.add(stmt);
    expect([HTLexicon.semicolon], consume: true);
    return stmt;
  }

  ImportExportDecl _parseExportStmt() {
    final keyword = advance(1); // not a keyword so don't use match
    late final ImportExportDecl stmt;
    // export some of the symbols from this or other source
    if (curTok.type == HTLexicon.bracesLeft) {
      advance(1);
      final showList = <IdentifierExpr>[];
      while (curTok.type != HTLexicon.bracesRight &&
          curTok.type != Semantic.endOfFile) {
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
        if (curTok.type != HTLexicon.bracesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == Semantic.consumingLineEndComment) {
          final token = advance(1);
          id.consumingLineEndComment = Comment(token.literal);
        }
        showList.add(id);
      }
      match(HTLexicon.bracesRight);
      String? fromPath;
      var hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
      if (!hasEndOfStmtMark && curTok.lexeme == HTLexicon.kFrom) {
        advance(1);
        final fromPathTok = match(Semantic.stringLiteral);
        final ext = path.extension(fromPathTok.literal);
        if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
          final err = HTError.importListOnNonHetuSource(
              filename: _currrentFileName,
              line: fromPathTok.line,
              column: fromPathTok.column,
              offset: fromPathTok.offset,
              length: fromPathTok.length);
          errors?.add(err);
        }
        hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
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
      final key = match(Semantic.stringLiteral);
      final hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
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

  AstNode _parseDeleteStmt() {
    var keyword = advance(1);
    final nextTok = peek(1);
    if (curTok.type == Semantic.identifier &&
        nextTok.type != HTLexicon.memberGet &&
        nextTok.type != HTLexicon.subGet) {
      final id = advance(1).lexeme;
      final hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
      return DeleteStmt(id,
          source: _currentSource,
          hasEndOfStmtMark: hasEndOfStmtMark,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      final expr = _parseExpr();
      final hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
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
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
        final empty = EmptyExpr(
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
    final keyword = match(HTLexicon.kNamespace);
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
    final keyword = advance(1);
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
    final genericParameters = _getGenericParams();
    match(HTLexicon.assign);
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

  ConstDecl _parseConstDecl(
      {String? classId, bool isStatic = false, bool isTopLevel = false}) {
    final keyword = match(HTLexicon.kConst);
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
    TypeExpr? declType;
    if (expect([HTLexicon.colon], consume: true)) {
      declType = _parseTypeExpr();
    }
    match(HTLexicon.assign);
    final constExpr = _parseExpr();
    if (!constExpr.isConst) {
      final err = HTError.notConstValue(
          filename: _currrentFileName,
          line: constExpr.line,
          column: constExpr.column,
          offset: constExpr.offset,
          length: constExpr.length);
      errors?.add(err);
    }
    final hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
    return ConstDecl(
      id,
      constExpr,
      classId: classId,
      declType: declType,
      hasEndOfStmtMark: hasEndOfStmtMark,
      isStatic: isStatic,
      source: _currentSource,
      line: keyword.line,
      column: keyword.column,
      offset: keyword.offset,
      length: constExpr.end - keyword.offset,
    );
  }

  VarDecl _parseVarDecl(
      {String? classId,
      bool isField = false,
      // bool typeInferrence = false,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isMutable = false,
      bool isTopLevel = false,
      bool lateFinalize = false,
      bool lateInitialize = false,
      AstNode? additionalInitializer,
      bool hasEndOfStatement = false}) {
    final keyword = advance(1);
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
    String? internalName;
    if (classId != null && isExternal) {
      if (!(_currentClass!.isExternal) && !isStatic) {
        final err = HTError.externalMember(
            filename: _currrentFileName,
            line: keyword.line,
            column: keyword.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      internalName = '$classId.${idTok.lexeme}';
    }
    TypeExpr? declType;
    if (expect([HTLexicon.colon], consume: true)) {
      declType = _parseTypeExpr();
    }
    AstNode? initializer;
    if (!lateFinalize) {
      if (expect([HTLexicon.assign], consume: true)) {
        initializer = _parseExpr();
      } else {
        initializer = additionalInitializer;
      }
    }
    bool hasEndOfStmtMark = hasEndOfStatement;
    if (hasEndOfStatement) {
      match(HTLexicon.semicolon);
    } else {
      hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
    }
    return VarDecl(id,
        internalName: internalName,
        classId: classId,
        declType: declType,
        initializer: initializer,
        hasEndOfStmtMark: hasEndOfStmtMark,
        isField: isField,
        isExternal: isExternal,
        isStatic: isStatic,
        isMutable: isMutable,
        isTopLevel: isTopLevel,
        lateFinalize: lateFinalize,
        lateInitialize: lateInitialize,
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
      startTok = advance(1);
      if (!isExternal &&
          (isStatic ||
              category == FunctionCategory.normal ||
              category == FunctionCategory.literal)) {
        if (expect([HTLexicon.bracketsLeft], consume: true)) {
          externalTypedef = match(Semantic.identifier).lexeme;
          match(HTLexicon.bracketsRight);
        }
      }
    }
    Token? id;
    late String internalName;
    // to distinguish getter and setter, and to give default constructor a name
    switch (category) {
      case FunctionCategory.constructor:
        _hasUserDefinedConstructor = true;
        if (curTok.type == Semantic.identifier) {
          id = advance(1);
        }
        internalName =
            (id == null) ? Semantic.constructor : '${Semantic.constructor}$id';
        break;
      case FunctionCategory.literal:
        if (curTok.type == Semantic.identifier) {
          id = advance(1);
        }
        internalName = (id == null)
            ? '${Semantic.anonymousFunction}${anonymousFunctionIndex++}'
            : id.lexeme;
        break;
      case FunctionCategory.getter:
        id = match(Semantic.identifier);
        internalName = '${Semantic.getter}$id';
        break;
      case FunctionCategory.setter:
        id = match(Semantic.identifier);
        internalName = '${Semantic.setter}$id';
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
        expect([HTLexicon.parenthesesLeft], consume: true)) {
      final startTok = curTok;
      hasParamDecls = true;
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while ((curTok.type != HTLexicon.parenthesesRight) &&
          (curTok.type != HTLexicon.bracketsRight) &&
          (curTok.type != HTLexicon.bracesRight) &&
          (curTok.type != Semantic.endOfFile)) {
        // 可选参数, 根据是否有方括号判断, 一旦开始了可选参数, 则不再增加参数数量arity要求
        if (!isOptional) {
          isOptional = expect([HTLexicon.bracketsLeft], consume: true);
          if (!isOptional && !isNamed) {
            //检查命名参数, 根据是否有花括号判断
            isNamed = expect([HTLexicon.bracesLeft], consume: true);
          }
        }
        if (!isNamed) {
          isVariadic = expect([HTLexicon.variadicArgs], consume: true);
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
        if (expect([HTLexicon.colon], consume: true)) {
          paramDeclType = _parseTypeExpr();
        }
        AstNode? initializer;
        if (expect([HTLexicon.assign], consume: true)) {
          if (isOptional || isNamed) {
            initializer = _parseExpr();
          } else {
            final lastTok = peek(-1);
            final err = HTError.argInit(
                filename: _currrentFileName,
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
        if (curTok.type != HTLexicon.bracketsRight &&
            curTok.type != HTLexicon.bracesRight &&
            curTok.type != HTLexicon.parenthesesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == Semantic.consumingLineEndComment) {
          final token = advance(1);
          param.consumingLineEndComment = Comment(token.literal);
        }
        paramDecls.add(param);
        if (isVariadic) {
          isFuncVariadic = true;
          break;
        }
      }
      if (isOptional) {
        match(HTLexicon.bracketsRight);
      } else if (isNamed) {
        match(HTLexicon.bracesRight);
      }

      final endTok = match(HTLexicon.parenthesesRight);

      // setter can only have one parameter
      if ((category == FunctionCategory.setter) && (minArity != 1)) {
        final err = HTError.setterArity(
            filename: _currrentFileName,
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
    if (expect([HTLexicon.singleArrow], consume: true)) {
      if (category == FunctionCategory.constructor ||
          category == FunctionCategory.setter) {
        final err = HTError.unexpected(
            Semantic.functionDefinition, Semantic.returnType,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      returnType = _parseTypeExpr();
    }
    // referring to another constructor
    else if (expect([HTLexicon.colon], consume: true)) {
      if (category != FunctionCategory.constructor) {
        final lastTok = peek(-1);
        final err = HTError.nonCotrWithReferCtor(
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors?.add(err);
      }
      if (isExternal) {
        final lastTok = peek(-1);
        final err = HTError.externalCtorWithReferCtor(
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors?.add(err);
      }
      final ctorCallee = advance(1);
      if (!HTLexicon.constructorCall.contains(ctorCallee.lexeme)) {
        final err = HTError.unexpected(Semantic.ctorCallExpr, curTok.lexeme,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: ctorCallee.offset,
            length: ctorCallee.length);
        errors?.add(err);
      }
      Token? ctorKey;
      if (expect([HTLexicon.memberGet], consume: true)) {
        ctorKey = match(Semantic.identifier);
        match(HTLexicon.parenthesesLeft);
      } else {
        match(HTLexicon.parenthesesLeft);
      }
      var positionalArgs = <AstNode>[];
      var namedArgs = <String, AstNode>{};
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
    AstNode? definition;
    if (curTok.type == HTLexicon.bracesLeft) {
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseBlockStmt(id: Semantic.functionCall);
    } else if (expect([HTLexicon.doubleArrow], consume: true)) {
      isExpressionBody = true;
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseExpr();
      hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
    } else if (expect([HTLexicon.assign], consume: true)) {
      final err = HTError.unsupported(Semantic.redirectingFunctionDefinition,
          filename: _currrentFileName,
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
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      if (category != FunctionCategory.literal) {
        expect([HTLexicon.semicolon], consume: true);
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
      bool isTopLevel = false}) {
    final keyword = match(HTLexicon.kClass);
    if (_currentClass != null && _currentClass!.isNested) {
      final err = HTError.nestedClass(
          filename: _currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: keyword.offset,
          length: keyword.length);
      errors?.add(err);
    }
    final id = match(Semantic.identifier);
    final genericParameters = _getGenericParams();
    TypeExpr? superClassType;
    if (expect([HTLexicon.kExtends], consume: true)) {
      if (curTok.lexeme == id.lexeme) {
        final err = HTError.extendsSelf(
            filename: _currrentFileName,
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
    final keyword = match(HTLexicon.kEnum);
    final id = match(Semantic.identifier);
    var enumerations = <IdentifierExpr>[];
    if (expect([HTLexicon.bracesLeft], consume: true)) {
      while (curTok.type != HTLexicon.bracesRight &&
          curTok.type != Semantic.endOfFile) {
        final enumIdTok = match(Semantic.identifier);
        final enumId =
            IdentifierExpr.fromToken(enumIdTok, source: _currentSource);
        if (curTok.type != HTLexicon.bracesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == Semantic.consumingLineEndComment) {
          final token = advance(1);
          enumId.consumingLineEndComment = Comment(token.literal);
        }
        enumerations.add(enumId);
      }
      match(HTLexicon.bracesRight);
    } else {
      expect([HTLexicon.semicolon], consume: true);
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
    final keyword = match(HTLexicon.kStruct);
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
    IdentifierExpr? prototypeId;
    if (expect([HTLexicon.kExtends], consume: true)) {
      final prototypeIdTok = match(Semantic.identifier);
      if (prototypeIdTok.lexeme == id.id) {
        final err = HTError.extendsSelf(
            filename: _currrentFileName,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
        errors?.add(err);
      }
      prototypeId =
          IdentifierExpr.fromToken(prototypeIdTok, source: _currentSource);
    } else if (id.id != HTLexicon.prototype) {
      prototypeId = IdentifierExpr(HTLexicon.prototype);
    }
    final savedStructId = _currentStructId;
    _currentStructId = id.id;
    final definition = <AstNode>[];
    final startTok = match(HTLexicon.bracesLeft);
    while (curTok.type != HTLexicon.bracesRight &&
        curTok.type != Semantic.endOfFile) {
      final stmt = _parseStmt(sourceType: ParseStyle.structDefinition);
      if (stmt != null) {
        definition.add(stmt);
      }
    }
    final endTok = match(HTLexicon.bracesRight);
    if (definition.isEmpty) {
      final empty = EmptyExpr(
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
      match(HTLexicon.kStruct);
      if (hasKeyword && expect([HTLexicon.kExtends], consume: true)) {
        final idTok = match(Semantic.identifier);
        prototypeId = IdentifierExpr.fromToken(idTok, source: _currentSource);
      }
    } else {
      prototypeId = IdentifierExpr(HTLexicon.prototype);
    }
    final structBlockStartTok = match(HTLexicon.bracesLeft);
    final fields = <StructObjField>[];
    while (curTok.type != HTLexicon.bracesRight &&
        curTok.type != Semantic.endOfFile) {
      if (curTok.type == Semantic.identifier ||
          curTok.type == Semantic.stringLiteral) {
        final keyTok = advance(1);
        late final StructObjField field;
        if (curTok.type == HTLexicon.comma ||
            curTok.type == HTLexicon.bracesRight) {
          final id = IdentifierExpr.fromToken(keyTok, source: _currentSource);
          field = StructObjField(key: keyTok.lexeme, value: id);
        } else {
          match(HTLexicon.colon);
          final value = _parseExpr();
          field = StructObjField(key: keyTok.lexeme, value: value);
        }
        if (curTok.type != HTLexicon.bracesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == Semantic.consumingLineEndComment) {
          final token = advance(1);
          field.consumingLineEndComment = Comment(token.literal);
        }
        fields.add(field);
      } else if (curTok.type == HTLexicon.spreadSyntax) {
        advance(1);
        final value = _parseExpr();
        final field = StructObjField(value: value, isSpread: true);
        if (curTok.type != HTLexicon.bracesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == Semantic.consumingLineEndComment) {
          final token = advance(1);
          field.consumingLineEndComment = Comment(token.literal);
        }
        fields.add(field);
      } else if (curTok.type == Semantic.singleLineComment ||
          curTok.type == Semantic.multiLineComment) {
        _handleComment();
      } else {
        final errTok = advance(1);
        final err = HTError.structMemberId(
            filename: _currrentFileName,
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
    match(HTLexicon.bracesRight);
    return StructObjExpr(fields,
        prototypeId: prototypeId,
        source: _currentSource,
        line: structBlockStartTok.line,
        column: structBlockStartTok.column,
        offset: structBlockStartTok.offset,
        length: curTok.offset - structBlockStartTok.offset);
  }
}
