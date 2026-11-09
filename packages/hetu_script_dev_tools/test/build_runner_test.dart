import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:hetu_script_dev_tools/builder.dart';
import 'package:test/test.dart';

void main() {
  test('hetuBindingBuilder generates binding code', () async {
    final builder = hetuBindingBuilder(BuilderOptions.empty);

    await testBuilder(
      builder,
      {
        'hetu_script|lib/binding.dart': '''
class HTBinding {
  const HTBinding();
}
''',
        'hetu_script_dev_tools|lib/person.dart': '''
import 'package:hetu_script/binding.dart';

@HTBinding()
class Person {
  static String meaning(int n) => 'The meaning of life is \$n';

  String name;
  Person(this.name);

  void greeting(String tag) {
    print('Hi! \$tag');
  }
}
''',
      },
      outputs: {
        'hetu_script_dev_tools|lib/person.hetu_binding.g.part': decodedMatches(
          allOf(
            contains('class PersonClassBinding extends HTExternalClass'),
            contains("case 'Person':"),
            contains("case 'Person.meaning':"),
            contains('object.greeting'),
          ),
        ),
      },
    );
  });
}
