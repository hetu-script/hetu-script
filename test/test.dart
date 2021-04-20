import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
        class Name {
          var first: str
          var last: str
          fun toString {
            return '{first: ${first}, last: ${last}}'
          }
        }
        class Stats {
          var age: int
          var height: float
          var weight: float
          fun toString {
            return '{age: ${age}, height: ${height}, weight: ${weight}}'
          }
        }
        class Person {
          var name: Map<str, Name>
          var stats: List<Stats>
          fun toString {
            return 'name: ${name}\nstats: ${stats}'
          }
        }
        var pp = Person.fromJson({
          'name': {
            'family' : {
              'first': 'Tom',
              'last': 'Riddle',
            },
            'guild' : {
              'first': 'Voldmort',
              'last': 'the Lord',
            }
          },
          'stats': [
            {'age': 12, 'height': 155.0, 'weight': 43.0}
          ]})
        print(pp.stats[0])
    ''', codeType: CodeType.script);
}
