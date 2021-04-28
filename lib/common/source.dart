import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

abstract class HTSource {
  Version? version;

  final Uri uri;

  String get fullName => '$uri';

  String get name => path.basename(fullName);

  HTSource(this.uri);
}
