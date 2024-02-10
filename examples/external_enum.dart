import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

enum Country {
  unitedStates,
  japan,
  iraq,
  ukraine,
}

class CountryEnumBinding extends HTExternalClass {
  CountryEnumBinding() : super('Country');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'values':
        return Country.values;
      case 'unitedStates':
        return Country.unitedStates;
      case 'japan':
        return Country.japan;
      case 'iraq':
        return Country.iraq;
      case 'ukraine':
        return Country.ukraine;
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String id) {
    switch (id) {
      case 'index':
        var i = object as Country;
        return i.index;
      case 'toString':
        var i = object as Country;
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            i.toString();
      default:
        throw HTError.undefined(id);
    }
  }
}

void main() {
  final hetu = Hetu();

  hetu.init(externalClasses: [CountryEnumBinding()]);

  final result = hetu.eval(r'''
      external enum Country {
        unitedStates,
        japan,
        iraq,
        ukraine,
      }
      
      function main {
        print(Country.values)
        var country = Country.Japan
        print(country.index);
        print(country.toString());
        return country
      }
      ''', invoke: 'main');

  print(result is Country);
}
