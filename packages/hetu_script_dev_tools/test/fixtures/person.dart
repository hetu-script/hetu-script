import 'package:hetu_script/binding.dart';

@HTBinding()
enum Ingredients {
  Apple,
  Banana,
  Cinnamon,
}

@HTBinding()
class Person {
  static String _level = '0';
  static String get level => _level;
  static set level(value) => _level = value;
  static String meaning(int n) => 'The meaning of life is $n';

  String get child => 'Tom';
  String name;
  String race;

  Person([this.name = 'Jimmy', this.race = 'Caucasian']);
  Person.withName(this.name, [this.race = 'Caucasian']);

  void greeting(String tag) {
    print('Hi! $tag');
  }
}
