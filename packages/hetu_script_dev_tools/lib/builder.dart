import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/binding/ht_binding_generator.dart';

/// Creates the build_runner builder for Hetu auto-binding.
Builder hetuBindingBuilder(BuilderOptions options) =>
    SharedPartBuilder([const HTBindingGenerator()], 'hetu_binding');
