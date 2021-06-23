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
  dynamic memberGet(String field, {bool error = true}) {
    switch (field) {
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
        if (error) {
          throw HTError.undefined(field);
        }
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String field) {
    switch (field) {
      case 'index':
        var i = object as Country;
        return i.index;
      case 'toString':
        var i = object as Country;
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            i.toString();
      default:
        throw HTError.undefined(field);
    }
  }
}

void main() async {
  var hetu = Hetu();

  await hetu.init(externalClasses: [CountryEnumBinding()]);

  await hetu.eval(r'''
      enum Race {
        caucasian,
        mongolian,
        african,
      }

      external enum Country // 不用写定义体

      fun main {
        print(Race.values)
        let race: Race = Race.african
        print(race)
        print(race.valueType)
        print(race.index)
        print(race.toString())
        print(race)
        
        print(Country.values)
        let country: Country = Country.Japan // 可以进行类型检查
        print(country.valueType)
        print(country.index)
        print(country.toString())
        print(country)
      }
      ''', invokeFunc: 'main');
}
