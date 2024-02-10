import '../ast/ast.dart';
import '../ast/visitor/recursive_ast_visitor.dart';
import '../lexicon/lexicon.dart';
import '../lexicon/lexicon_hetu.dart';
import '../analyzer/analysis_error.dart';
import '../error/error.dart';

/// A interpreter that computes the value of a constant expression before compilation.
/// If the AstNode provided is non-constant value, do nothing.
class HTConstantInterpreter extends RecursiveASTVisitor<void> {
  late final HTLexicon _lexicon;

  HTConstantInterpreter({HTLexicon? lexicon})
      : _lexicon = lexicon ?? HTLexiconHetu();

  /// Errors of a single file
  late List<HTAnalysisError> errors = [];

  final List<ASTNode> _visitingInitializers = [];

  void evalAstNode(ASTNode node) => node.accept(this);

  @override
  void visitStringInterpolationExpr(ASTStringInterpolation node) {
    final interpolations = <String>[];
    for (final expr in node.interpolations) {
      expr.accept(this);
      if (!expr.isConstValue) {
        return;
      }
      interpolations.add(_lexicon.stringify(expr.value));
    }
    var text = node.text;
    for (var i = 0; i < interpolations.length; ++i) {
      text = text.replaceAll(
          '${_lexicon.stringInterpolationStart}$i${_lexicon.stringInterpolationEnd}',
          interpolations[i]);
    }
    node.value = text;
  }

  @override
  void visitIdentifierExpr(IdentifierExpr node) {
    if (node.isLocal) {
      final ASTNode? ast =
          node.analysisNamespace!.memberGet(node.id, throws: false);
      if (ast != null) {
        ast.accept(this);
        if (ast.isConstValue) {
          node.value = ast.value;
        }
      }
    } else {
      // static member of a class
    }
  }

  @override
  void visitSpreadExpr(SpreadExpr node) {
    node.subAccept(this);
  }

  @override
  void visitCommaExpr(CommaExpr node) {
    node.subAccept(this);
  }

  @override
  void visitListExpr(ListExpr node) {
    node.subAccept(this);
  }

  @override
  void visitInOfExpr(InOfExpr node) {
    node.subAccept(this);
  }

  @override
  void visitGroupExpr(GroupExpr node) {
    node.subAccept(this);
    if (node.inner.isConstValue) {
      node.value = node.inner.value;
    }
  }

  @override
  void visitNominalTypeExpr(NominalTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitParamTypeExpr(ParamTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitFunctionTypeExpr(FuncTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitFieldTypeExpr(FieldTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitStructuralTypeExpr(StructuralTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitGenericTypeParamExpr(GenericTypeParameterExpr node) {
    node.subAccept(this);
  }

  /// -e, !e，++e, --e
  @override
  void visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    node.subAccept(this);
    if (node.op == _lexicon.logicalNot && node.object.isConstValue) {
      node.value = !node.object.value;
    } else if (node.op == _lexicon.negative &&
        node.object is ASTLiteralInteger) {
      node.value = -(node.object as ASTLiteralInteger).value;
    }
  }

  @override
  void visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    node.subAccept(this);
  }

  /// *, /, ~/, %, +, -, <, >, <=, >=, ==, !=, &&, ||
  @override
  void visitBinaryExpr(BinaryExpr node) {
    node.left.accept(this);
    node.right.accept(this);
    final left = node.left.value;
    final right = node.right.value;
    if (node.op == _lexicon.multiply) {
      if (left != null && right != null) {
        node.value = left * right;
      }
    } else if (node.op == _lexicon.devide) {
      if (left != null && right != null) {
        node.value = left / right;
      }
    } else if (node.op == _lexicon.truncatingDevide) {
      if (left != null && right != null) {
        node.value = left ~/ right;
      }
    } else if (node.op == _lexicon.modulo) {
      if (left != null && right != null) {
        node.value = left % right;
      }
    } else if (node.op == _lexicon.add) {
      if (left != null && right != null) {
        node.value = left + right;
      }
    } else if (node.op == _lexicon.subtract) {
      if (left != null && right != null) {
        node.value = left - right;
      }
    } else if (node.op == _lexicon.lesser) {
      if (left != null && right != null) {
        node.value = left < right;
      }
    } else if (node.op == _lexicon.lesserOrEqual) {
      if (left != null && right != null) {
        node.value = left <= right;
      }
    } else if (node.op == _lexicon.greater) {
      if (left != null && right != null) {
        node.value = left > right;
      }
    } else if (node.op == _lexicon.greaterOrEqual) {
      if (left != null && right != null) {
        node.value = left >= right;
      }
    } else if (node.op == _lexicon.equal) {
      if (left != null && right != null) {
        node.value = left == right;
      }
    } else if (node.op == _lexicon.notEqual) {
      if (left != null && right != null) {
        node.value = left != right;
      }
    } else if (node.op == _lexicon.logicalAnd) {
      if (left != null && right != null) {
        node.value = left && right;
      }
    } else if (node.op == _lexicon.logicalOr) {
      if (left != null && right != null) {
        node.value = left || right;
      }
    }
  }

  /// e1 ? e2 : e3
  @override
  void visitTernaryExpr(TernaryExpr node) {
    node.subAccept(this);
    if (node.condition.isConstValue && node.value is bool) {
      bool condition = node.condition.value;
      if (condition) {
        node.value = node.thenBranch.value;
      } else {
        node.value = node.elseBranch.value;
      }
    }
  }

  @override
  void visitAssignExpr(AssignExpr node) {
    node.subAccept(this);
  }

  @override
  void visitMemberExpr(MemberExpr node) {
    node.subAccept(this);
  }

  @override
  void visitSubExpr(SubExpr node) {
    node.subAccept(this);
  }

  @override
  void visitCallExpr(CallExpr node) {
    node.subAccept(this);
  }

  @override
  void visitAssertStmt(AssertStmt node) {
    node.subAccept(this);
  }

  @override
  void visitThrowStmt(ThrowStmt node) {
    node.subAccept(this);
  }

  @override
  void visitExprStmt(ExprStmt node) {
    node.subAccept(this);
  }

  @override
  void visitBlockStmt(BlockStmt node) {
    node.subAccept(this);
  }

  @override
  void visitReturnStmt(ReturnStmt node) {
    node.subAccept(this);
  }

  @override
  void visitIf(IfExpr node) {
    node.subAccept(this);
    if (node.condition.isConstValue && node.condition.value is bool) {
      bool condition = node.condition.value;
      if (condition) {
        node.value = node.thenBranch.value;
      } else {
        node.value = node.elseBranch?.value;
      }
    }
  }

  @override
  void visitWhileStmt(WhileStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDoStmt(DoStmt node) {
    node.subAccept(this);
  }

  @override
  void visitForStmt(ForExpr node) {
    node.subAccept(this);
  }

  @override
  void visitForRangeStmt(ForRangeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitSwitch(SwitchStmt node) {
    node.subAccept(this);
  }

  @override
  void visitBreakStmt(BreakStmt node) {
    node.subAccept(this);
  }

  @override
  void visitContinueStmt(ContinueStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDeleteStmt(DeleteStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDeleteMemberStmt(DeleteMemberStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDeleteSubStmt(DeleteSubStmt node) {
    node.subAccept(this);
  }

  @override
  void visitImportExportDecl(ImportExportDecl node) {
    node.subAccept(this);
  }

  @override
  void visitNamespaceDecl(NamespaceDecl node) {
    node.subAccept(this);
  }

  @override
  void visitTypeAliasDecl(TypeAliasDecl node) {
    node.subAccept(this);
  }

  // @override
  // void visitConstDecl(ConstDecl node) {
  //   node.subAccept(this);
  // }

  @override
  void visitVarDecl(VarDecl node) {
    /// Skip if the value is already been computed.
    if (node.isConstValue) return;
    if (_visitingInitializers.contains(node)) {
      final err = HTError.circleInit(node.id.id,
          filename: node.source!.fullName,
          line: node.line,
          column: node.column,
          offset: node.offset,
          length: node.length);
      errors.add(HTAnalysisError.fromError(err,
          filename: node.source!.fullName,
          line: node.line,
          column: node.column,
          offset: node.offset,
          length: node.length));
    } else {
      _visitingInitializers.add(node);
      node.subAccept(this);
      if (node.isConst) {
        if (!node.initializer!.isConstValue) {
          final err = HTAnalysisError.constValue(node.id.id,
              filename: node.source!.fullName,
              line: node.initializer!.line,
              column: node.initializer!.column,
              offset: node.initializer!.offset,
              length: node.initializer!.length);
          errors.add(err);
        } else {
          node.value = node.initializer!.value;
        }
      }
      _visitingInitializers.remove(node);
    }
  }

  @override
  void visitDestructuringDecl(DestructuringDecl node) {
    node.subAccept(this);
  }

  @override
  void visitParamDecl(ParamDecl node) {
    node.subAccept(this);
  }

  @override
  void visitReferConstructCallExpr(RedirectingConstructorCallExpr node) {
    node.subAccept(this);
  }

  @override
  void visitFuncDecl(FuncDecl node) {
    node.subAccept(this);
  }

  @override
  void visitClassDecl(ClassDecl node) {
    node.subAccept(this);
  }

  @override
  void visitEnumDecl(EnumDecl node) {
    node.subAccept(this);
  }

  @override
  void visitStructDecl(StructDecl node) {
    node.subAccept(this);
  }

  @override
  void visitStructObjExpr(StructObjExpr node) {
    node.subAccept(this);
  }

  @override
  void visitStructObjField(StructObjField node) {
    node.subAccept(this);
  }
}
