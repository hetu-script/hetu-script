import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

import 'fixtures/gen/person.g.dart';
import 'fixtures/person.dart';

void main() {
  test('generated bindings work in Hetu', () {
    final hetu = Hetu();
    hetu.init(externalClasses: [PersonClassBinding(), IngredientsClassBinding()]);

    final result = hetu.eval(r'''
      external class Person {
        var race: string
        constructor([name: string = 'Jimmy', race: string = 'Caucasian']);
        get child
        static function meaning(n: num)
        static get level
        static set level (value: string)
        constructor withName(name: string, [race: string = 'Caucasian'])
        var name
        function greeting(tag: string)
      }
      external class Ingredients {
        static get Apple
        static get Banana
        static get Cinnamon
      }
      function main {
        var p = Person.withName('Jimmy')
        p.greeting('jimmy')
        p.name = 'John'
        Person.level = '3'
        return {
          name: p.name,
          child: p.child,
          level: Person.level,
          meaning: Person.meaning(42),
          ingredient: Ingredients.Banana.name,
        }
      }
    ''', type: HTResourceType.hetuModule, invoke: 'main');

    expect(result, isNotNull);
    expect(result['name'], 'John');
    expect(result['child'], 'Tom');
    expect(result['level'], '3');
    expect(result['meaning'], 'The meaning of life is 42');
    expect(result['ingredient'], 'Banana');
  });
}
