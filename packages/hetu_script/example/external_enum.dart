import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

enum Country {
  UnitedStates,
  Japan,
  Iraq,
  Ukraine,
}

class CountryEnumBinding extends HTExternalClass {
  CountryEnumBinding() : super('Country');

  @override
  dynamic memberGet(String varName) {
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
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    switch (varName) {
      case 'index':
        var i = object as Country;
        return i.index;
      case 'toString':
        var i = object as Country;
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            i.toString();
      default:
        throw HTError.undefined(varName);
    }
  }
}

void main() {
  var hetu = Hetu();

  hetu.init(externalClasses: [CountryEnumBinding()]);

  final result = hetu.eval(r'''
      external enum Country {
        UnitedStates,
        Japan,
        Iraq,
        Ukraine,
      }

      fun main {
        print(Country.values)
        var country = Country.Japan
        print(country.index);
        print(country.toString());
        return country
      }
      ''', invokeFunc: 'main');

  print(result is Country);
}
