/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure (like instances of the class [RecursiveAstVisitor]). In addition,
/// when a node of a specific type is visited not only will the visit method for
/// that specific type of node be invoked, but additional methods for the
/// superclasses of that node will also be invoked. For example, using an
/// instance of this class to visit a [Block] will cause the method [visitBlock]
/// to be invoked but will also cause the methods [visitStatement] and
/// [visitNode] to be subsequently invoked. This allows visitors to be written
/// that visit all statements without needing to override the visit method for
/// each of the specific subclasses of [Statement].
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or explicitly invoke the more general visit method. Failure to
/// do so will cause the visit methods for superclasses of the node to not be
/// invoked and will cause the children of the visited node to not be visited.
abstract class GeneralizingAstVisitor {}
