import 'dart:io';

import 'package:hetu_script_dev_tools/src/binding/binding_emitter.dart';
import 'package:hetu_script_dev_tools/src/binding/binding_generator.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  final fixturePath = path.join(Directory.current.path, 'test', 'fixtures');
  final personPath = path.join(fixturePath, 'person.dart');

  group('BindingGenerator', () {
    test('resolves @HTBinding classes and enums', () async {
      final generator = BindingGenerator(
        BindingGeneratorOptions(
          userLibPaths: [fixturePath],
          outputPath: path.join(fixturePath, 'gen'),
          scriptOutputPath: path.join(fixturePath, 'gen_ht'),
        ),
      );

      final files = await generator.generate();
      expect(files, hasLength(1));

      final file = files.single;
      expect(file.filePath, personPath);
      expect(file.classes, hasLength(1));
      expect(file.enums, hasLength(1));

      final cls = file.classes.single;
      expect(cls.name, 'Person');
      expect(cls.constructors, hasLength(2));
      expect(cls.staticMethods.map((m) => m.name), contains('meaning'));
      expect(cls.instanceMethods.map((m) => m.name), contains('greeting'));
      expect(cls.instanceFields.map((f) => f.name), containsAll(['name', 'race']));

      final enum_ = file.enums.single;
      expect(enum_.name, 'Ingredients');
      expect(enum_.constants, containsAll(['Apple', 'Banana', 'Cinnamon']));
    });

    test('emits Dart and Hetu source', () async {
      final generator = BindingGenerator(
        BindingGeneratorOptions(
          userLibPaths: [fixturePath],
          outputPath: path.join(fixturePath, 'gen'),
          scriptOutputPath: path.join(fixturePath, 'gen_ht'),
        ),
      );

      final files = await generator.generate();
      final emitter = BindingEmitter();

      final dartSource = emitter.emitDart(files.single);
      expect(dartSource, contains('class PersonClassBinding extends HTExternalClass'));
      expect(dartSource, contains("case 'Person.withName':"));
      expect(dartSource, contains('object.greeting'));

      final hetuSource = emitter.emitHetu(files.single);
      expect(hetuSource, contains('external class Person'));
      expect(hetuSource, contains('constructor withName'));
      expect(hetuSource, contains('external class Ingredients'));
    });
  });
}
