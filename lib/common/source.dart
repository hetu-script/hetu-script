import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

abstract class HTSource {
  Version? version;

  final String fullName;

  late final Uri uri;

  bool evaluated = false;

  String get name => path.basename(fullName);

  HTSource(this.fullName) {
    uri = Uri(path: fullName);
  }
}

abstract class HTCompilation {
  Iterable<String> get keys;

  Iterable<HTSource> get sources;

  bool contains(String fullName);

  HTSource fetch(String fullName);
}
