import '../ast/ast.dart';
import '../grammar/lexicon.dart';
import '../shared/stringify.dart';
import '../analyzer/analysis_error.dart';

/// A interpreter that computes the constant value before compilation.
/// If the AstNode provided is non-constant value, return null.
class HTConstantInterpreter implements AbstractAstVisitor<void> {
  /// Errors of a single file
  late List<HTAnalysisError> errors = [];

  void evalAstNode(AstNode node) => node.accept(this);

  @override
  void visitCompilation(AstCompilation node) {
    node.subAccept(this);
  }

  @override
  void visitCompilationUnit(AstSource node) {
    node.subAccept(this);
  }

  @override
  void visitEmptyExpr(EmptyLine node) {}

  @override
  void visitNullExpr(NullExpr node) {}

  @override
  void visitBooleanExpr(BooleanLiteralExpr node) {}

  @override
  void visitIntLiteralExpr(IntegerLiteralExpr node) {}

  @override
  void visitFloatLiteralExpr(FloatLiteralExpr node) {}

  @override
  void visitStringLiteralExpr(StringLiteralExpr node) {}

  @override
  void visitStringInterpolationExpr(StringInterpolationExpr node) {
    final interpolations = <String>[];
    for (final expr in node.interpolations) {
      expr.accept(this);
      if (!expr.isConstValue) {
        return;
      }
      interpolations.add(stringify(expr.value));
    }
    var text = node.text;
    for (var i = 0; i < interpolations.length; ++i) {
      text = text.replaceAll(
          '${HTLexicon.functionBlockStart}$i${HTLexicon.functionBlockEnd}',
          interpolations[i]);
    }
    node.value = text;
  }

  @override
  void visitIdentifierExpr(IdentifierExpr node) {
    node.subAccept(this);
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
  void visitTypeExpr(TypeExpr node) {
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
    if (node.op == HTLexicon.logicalNot && node.object.isConstValue) {
      node.value = !node.object.value;
    } else if (node.op == HTLexicon.negative &&
        node.object is IntegerLiteralExpr) {
      node.value = -(node.object as IntegerLiteralExpr).value;
    }
  }

  @override
  void visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    node.subAccept(this);
  }

  /// *, /, ~/, %, +, -, <, >, <=, >=, ==, !=, &&, ||
  @override
  void visitBinaryExpr(BinaryExpr node) {
    final left = node.left.value;
    final right = node.right.value;
    switch (node.op) {
      case HTLexicon.multiply:
        if (left != null && right != null) {
          node.value = left * right;
        }
        break;
      case HTLexicon.devide:
        if (left != null && right != null) {
          node.value = left / right;
        }
        break;
      case HTLexicon.truncatingDevide:
        if (left != null && right != null) {
          node.value = left ~/ right;
        }
        break;
      case HTLexicon.modulo:
        if (left != null && right != null) {
          node.value = left % right;
        }
        break;
      case HTLexicon.add:
        if (left != null && right != null) {
          node.value = left + right;
        }
        break;
      case HTLexicon.subtract:
        if (left != null && right != null) {
          node.value = left - right;
        }
        break;
      case HTLexicon.lesser:
        if (left != null && right != null) {
          node.value = left < right;
        }
        break;
      case HTLexicon.lesserOrEqual:
        if (left != null && right != null) {
          node.value = left <= right;
        }
        break;
      case HTLexicon.greater:
        if (left != null && right != null) {
          node.value = left > right;
        }
        break;
      case HTLexicon.greaterOrEqual:
        if (left != null && right != null) {
          node.value = left >= right;
        }
        break;
      case HTLexicon.equal:
        if (left != null && right != null) {
          node.value = left == right;
        }
        break;
      case HTLexicon.notEqual:
        if (left != null && right != null) {
          node.value = left != right;
        }
        break;
      case HTLexicon.logicalAnd:
        if (left != null && right != null) {
          node.value = left && right;
        }
        break;
      case HTLexicon.logicalOr:
        if (left != null && right != null) {
          node.value = left || right;
        }
        break;
    }
  }

  /// e1 ? e2 : e3
  @override
  void visitTernaryExpr(TernaryExpr node) {
    node.subAccept(this);
  }

  @override
  void visitMemberExpr(MemberExpr node) {
    node.subAccept(this);
  }

  @override
  void visitMemberAssignExpr(MemberAssignExpr node) {
    node.subAccept(this);
  }

  @override
  void visitSubExpr(SubExpr node) {
    node.subAccept(this);
  }

  @override
  void visitSubAssignExpr(SubAssignExpr node) {
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
  void visitIf(IfStmt node) {
    node.subAccept(this);
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
  void visitForStmt(ForStmt node) {
    node.subAccept(this);
  }

  @override
  void visitForRangeStmt(ForRangeStmt node) {
    node.subAccept(this);
  }

  @override
  void visitWhen(WhenStmt node) {
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
    node.subAccept(this);
    if (node.isConst && !node.initializer!.isConstValue) {
      final err = HTAnalysisError.constValue(
          filename: node.source!.fullName,
          line: node.initializer!.line,
          column: node.initializer!.column,
          offset: node.initializer!.offset,
          length: node.initializer!.length);
      errors.add(err);
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
