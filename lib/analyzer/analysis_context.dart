import '../declaration/namespace/namespace.dart';
import 'analysis_result.dart';

class HTAnalysisContext {
  final modules = <String, HTModuleAnalysisResult>{};

  final declarations = <String, HTNamespace>{};
}
