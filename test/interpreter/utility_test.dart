import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('utilities -', () {
    // test('json conversion', () {
    //   final result = hetu.eval('''
    //     class SomePerson {
    //       var age = 17
    //       var name = 'Jimmy'
    //       var klass = 'farmer'
    //     }
    //     function JsonTest {
    //       var p = SomePerson.fromJson({'age': 8, 'name': 'Lawrence', 'klass': 'magician'})
    //       return p.toJson().toString()
    //     }
    //   ''', invoke: 'JsonTest');
    //   expect(
    //     result,
    //     '{age: 8, name: Lawrence, klass: magician}',
    //   );
    // });
    // test('json assign', () {
    //   final result = hetu.eval(r'''
    //     class Name {
    //       var first: str
    //       var last: str
    //       function toString {
    //         return '{first: ${first}, last: ${last}}'
    //       }
    //     }
    //     class Stats {
    //       var age: int
    //       var height: float
    //       var weight: float
    //       function toString {
    //         return '{age: ${age}, height: ${height}, weight: ${weight}}'
    //       }
    //     }
    //     class Profile {
    //       var name: Map<str, Name>
    //       var stats: List<Stats>
    //       function toString {
    //         return 'name: ${name}\nstats: ${stats}'
    //       }
    //     }
    //     function jsonAssign {
    //       var pp = Profile.fromJson({
    //         'name': {
    //           'family' : {
    //             'first': 'Tom',
    //             'last': 'Riddle',
    //           },
    //           'guild' : {
    //             'first': 'Voldmort',
    //             'last': 'the Lord',
    //           }
    //         },
    //         'stats': [
    //           {'age': 12, 'height': 155.0, 'weight': 43.0}
    //         ]})
    //       return pp.stats[0].toString()
    //     }
    //   ''', invoke: 'jsonAssign');
    //   expect(
    //     result,
    //     '{age: 12, height: 155.0, weight: 43.0}',
    //   );
    // });
  });
}
