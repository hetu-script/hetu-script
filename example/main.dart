import 'package:hetu_script/hetu.dart';

import 'dart:io';

void main() {
  hetu.init(workingDir: 'ht_example');
  hetu.evalf('ht_example\\privatemain.ht', invokeFunc: 'main');
  // stdout.write('\x1B[32m');
  // print('Hetu init failed!');
  // stdout.write('\x1B[m');
}
