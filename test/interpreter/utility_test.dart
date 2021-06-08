import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();

  group('utilities -', () {
    // test('json conversion', () async {
    //   final result = await hetu.eval('''
    //     class SomePerson {
    //       var age = 17
    //       var name = 'Jimmy'
    //       var klass = 'farmer'
    //     }
    //     fun JsonTest {
    //       var p = SomePerson.fromJson({'age': 8, 'name': 'Lawrence', 'klass': 'magician'})
    //       return p.toJson().toString()
    //     }
    //   ''', invokeFunc: 'JsonTest');
    //   expect(
    //     result,
    //     '{age: 8, name: Lawrence, klass: magician}',
    //   );
    // });
    // test('json assign', () async {
    //   final result = await hetu.eval(r'''
    //     class Name {
    //       var first: str
    //       var last: str
    //       fun toString {
    //         return '{first: ${first}, last: ${last}}'
    //       }
    //     }
    //     class Stats {
    //       var age: int
    //       var height: float
    //       var weight: float
    //       fun toString {
    //         return '{age: ${age}, height: ${height}, weight: ${weight}}'
    //       }
    //     }
    //     class Profile {
    //       var name: Map<str, Name>
    //       var stats: List<Stats>
    //       fun toString {
    //         return 'name: ${name}\nstats: ${stats}'
    //       }
    //     }
    //     fun jsonAssign {
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
    //   ''', invokeFunc: 'jsonAssign');
    //   expect(
    //     result,
    //     '{age: 12, height: 155.0, weight: 43.0}',
    //   );
    // });
  });
}
