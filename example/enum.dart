import 'package:hetu_script/hetu_script.dart';

enum Country {
  UnitedStates,
  Japan,
  Iraq,
  Ukraine,
}

class CountryEnumBinding extends HTExternalClass {
  CountryEnumBinding() : super('Country');

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'values':
        return Country.values;
      case 'UnitedStates':
        return Country.UnitedStates;
      case 'Japan':
        return Country.Japan;
      case 'Iraq':
        return Country.Iraq;
      case 'Ukraine':
        return Country.Ukraine;
      default:
        throw HTErrorUndefined(varName);
    }
  }

  @override
  dynamic instanceFetch(dynamic instance, String varName) {
    switch (varName) {
      case 'typeid':
        return HTTypeId('Country');
      case 'index':
        var i = instance as Country;
        return i.index;
      case 'toString':
        var i = instance as Country;
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            i.toString();
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

void main() async {
  var hetu = HTAstInterpreter();

  await hetu.init(externalClasses: [CountryEnumBinding()]);

  await hetu.eval(r'''
      enum Race {
        Caucasian,
        Mongolian,
        African,
      }

      external enum Country // 不用写定义体

      fun main {
        print(Race.values)
        let race: Race = Race.African
        print(race.typeid)
        print(race.index)
        print(race.toString())
        print(race)
        
        print(Country.values)
        let country: Country = Country.Japan // 可以进行类型检查
        print(country.typeid)
        print(country.index)
        print(country.toString())
        print(country)
      }
      ''', invokeFunc: 'main');
}
