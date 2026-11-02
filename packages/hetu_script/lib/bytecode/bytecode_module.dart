import 'dart:typed_data';

import 'package:hetu_script/hetu_script.dart';
import 'package:pub_semver/pub_semver.dart';

import '../value/namespace/namespace.dart';
import 'bytecode_reader.dart';
import '../constant/global_constant_table.dart';

class HTCallSiteInfo {
  final int nextIp;
  final bool isNullable;
  final bool isConstructorCall;
  final String? objectId;
  final List<String> namedKeys;
  final int positionalArgCount;
  final List<int> positionalArgFlags;
  final bool hasSpread;

  const HTCallSiteInfo({
    required this.nextIp,
    required this.isNullable,
    required this.isConstructorCall,
    required this.objectId,
    required this.namedKeys,
    required this.positionalArgCount,
    required this.positionalArgFlags,
    required this.hasSpread,
  });
}

/// A bytecode module contains the compiled bytes,
/// after the execution of the interpreter, it will also contain namespaces & values.
class HTBytecodeModule extends HTGlobalConstantTable with BytecodeReader {
  /// The version of this module, will be read from the bytes later.
  Version? version;

  /// The compiled time of this module, will be read from the bytes later.
  String? compiledAt;

  /// The name of this module.
  final String id;

  /// An interpreted source is exist as a namespace in bytecode module.
  /// This is empty until interpreter insert the evaled values.
  final Map<String, HTNamespace> namespaces = {};

  /// An interpreted non-source, such as JSON, is exist as a value in bytecode module.
  /// This is empty until interpreter insert the evaled values.
  final Map<String, HTJsonSource> jsonSources = {};

  /// time stamp of the start time of the execution of this module
  int timestamp = 0;

  String? invoke;
  List<dynamic> positionalArgs = const [];
  Map<String, dynamic> namedArgs = const {};

  final _callSiteInfoCache = <int, HTCallSiteInfo>{};
  int callSiteCacheHits = 0;
  int callSiteCacheMisses = 0;

  int get callSiteCacheSize => _callSiteInfoCache.length;

  double get callSiteCacheHitRate {
    final total = callSiteCacheHits + callSiteCacheMisses;
    return total == 0 ? 0 : callSiteCacheHits / total;
  }

  HTCallSiteInfo? getCallSiteInfo(int instructionIp) {
    final info = _callSiteInfoCache[instructionIp];
    if (info == null) {
      ++callSiteCacheMisses;
    } else {
      ++callSiteCacheHits;
    }
    return info;
  }

  void cacheCallSiteInfo(int instructionIp, HTCallSiteInfo info) {
    _callSiteInfoCache[instructionIp] = info;
  }

  late final List<int> _intConstants = constants[int]! as List<int>;
  late final List<double> _floatConstants = constants[double]! as List<double>;
  late final List<String> _stringConstants = constants[String]! as List<String>;

  int getConstInt(int index) => _intConstants[index];

  double getConstFloat(int index) => _floatConstants[index];

  /// fetch a contant value defined within any namespace of this module.
  String getConstString([int? index]) {
    final constantIndex = index ?? readUint16();
    return _stringConstants[constantIndex];
  }

  HTBytecodeModule({
    required this.id,
    required Uint8List bytes,
  }) {
    this.bytes = bytes;
  }

  void init({
    String? invoke,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) {
    timestamp = DateTime.now().millisecondsSinceEpoch;
    ip = 0;
    this.invoke = invoke;
    this.positionalArgs = positionalArgs;
    this.namedArgs = namedArgs;
  }
}
