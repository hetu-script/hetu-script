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

void main() {
  var hetu = Hetu();

  hetu.init(externalClasses: [CountryEnumBinding()]);

  hetu.eval(r'''
      enum Race {
        caucasian,
        mongolian,
        african,
      }

      external enum Country {
        UnitedStates,
        Japan,
        Iraq,
        Ukraine,
      }

      fun main {
        print(Race.values)
        var race: Race = Race.african
        print(race)
        print(typeof race)
        print(race.toString())
        
        // print(Country.values)
        // var country: Country = Country.Japan // 可以进行类型检查
        // print(country)
        // print(typeof country)
        // print(country.toString())
      }
      ''', invokeFunc: 'main');
}
