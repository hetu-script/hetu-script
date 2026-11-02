import 'dart:typed_data';

import 'package:hetu_script/bytecode/bytecode_module.dart';
import 'package:test/test.dart';

void main() {
  test('bytecode module reads typed constants through cached tables', () {
    final module = HTBytecodeModule(
      id: 'constants',
      bytes: Uint8List.fromList([0, 1]),
    );
    module.addGlobalConstant<int>(42);
    module.addGlobalConstant<double>(3.5);
    module.addGlobalConstant<String>('zero');
    module.addGlobalConstant<String>('你好');

    expect(module.getConstInt(0), 42);
    expect(module.getConstFloat(0), 3.5);
    expect(module.getConstString(0), 'zero');
    expect(module.getConstString(), '你好');
    expect(module.ip, 2);

    module.addGlobalConstant<int>(43);
    module.addGlobalConstant<double>(4.5);
    module.addGlobalConstant<String>('added later');
    expect(module.getConstInt(1), 43);
    expect(module.getConstFloat(1), 4.5);
    expect(module.getConstString(2), 'added later');
  });
}
